"""Exporta el modelo de Enterprise Architect (.qea) del GIP a Markdown legible por Claude Code.

Uso: python3 -I export_qea.py <ruta.qea> <carpeta_salida>
Genera:
  README.md            índice
  clases.md            entidades, componentes, interfaces y workflow (Business Layer)
  arquitectura.md      componentes de la arquitectura en capas
  casos-de-uso.md      lista de casos de uso del sistema
  secuencias/CUS-XX.md un archivo por diagrama de secuencia
"""
import os
import re
import sqlite3
import sys

FRAG = {0: "alt", 1: "opt", 2: "break", 3: "par", 4: "loop", 5: "critical",
        6: "neg", 7: "assert", 8: "strict", 9: "seq", 10: "ignore", 11: "consider"}


def clean(t):
    if not t:
        return ""
    t = re.sub(r"<[^>]+>", "", t)
    return t.replace("\r\n", " ").replace("\n", " ").strip()


def main(db_path, out):
    c = sqlite3.connect(db_path)
    c.row_factory = sqlite3.Row
    os.makedirs(os.path.join(out, "secuencias"), exist_ok=True)

    pk = {r["Package_ID"]: r for r in c.execute("select * from t_package")}

    def ppath(pid):
        parts = []
        while pid in pk and pk[pid]["Parent_ID"]:
            parts.append(pk[pid]["Name"])
            pid = pk[pid]["Parent_ID"]
        return "/".join(reversed(parts))

    objs = {r["Object_ID"]: r for r in c.execute("select * from t_object")}

    # ---------------- clases.md ----------------
    detalle = [p for p in pk if "3.1.2 Detalle Del Dise" in ppath(p)]
    order = ["Entidades", "Interfaces", "Componentes", "Workflow"]

    def sort_key(pid):
        path = ppath(pid)
        for i, k in enumerate(order):
            if f"/{k}" in path:
                return (i, path)
        return (9, path)

    lines = ["# Diseño detallado de la Business Layer (exportado de ProyectoUML.qea)", "",
             "Fuente de verdad del diseño. Generado automáticamente: no editar a mano; "
             "regenerar con `tool/export_qea.py` cuando cambie el modelo de EA.", "",
             "Dependencias permitidas: Workflow → Componentes → Interfaces → Entidades. "
             "Getters/setters omitidos cuando son triviales.", ""]
    for pid in sorted(detalle, key=sort_key):
        rows = [o for o in objs.values() if o["Package_ID"] == pid
                and o["Object_Type"] in ("Class", "Interface", "Enumeration")]
        if not rows:
            continue
        lines += [f"## {ppath(pid).split('3.1.2 Detalle Del Diseño/')[-1]}", ""]
        for o in sorted(rows, key=lambda r: r["Name"]):
            oid = o["Object_ID"]
            kind = {"Class": "class", "Interface": "interface", "Enumeration": "enum"}[o["Object_Type"]]
            if o["Abstract"] == "1" and kind == "class":
                kind = "abstract class"
            parents = [objs[x["End_Object_ID"]]["Name"] for x in c.execute(
                "select End_Object_ID from t_connector where Start_Object_ID=? and Connector_Type='Generalization'", (oid,))
                if x["End_Object_ID"] in objs]
            impls = [objs[x["End_Object_ID"]]["Name"] for x in c.execute(
                "select End_Object_ID from t_connector where Start_Object_ID=? and Connector_Type='Realisation'", (oid,))
                if x["End_Object_ID"] in objs]
            head = f"### `{o['Name']}` ({kind})"
            if parents:
                head += f" extends {', '.join(parents)}"
            if impls:
                head += f" implements {', '.join(impls)}"
            lines += [head, ""]
            if clean(o["Note"]):
                lines += [f"> {clean(o['Note'])}", ""]
            attrs = list(c.execute("select * from t_attribute where Object_ID=? order by Pos", (oid,)))
            if attrs:
                if kind == "enum":
                    lines.append("Valores: " + ", ".join(f"`{a['Name']}`" for a in attrs))
                else:
                    lines.append("Atributos:")
                    for a in attrs:
                        vis = {"Private": "-", "Public": "+", "Protected": "#"}.get(a["Scope"], "~")
                        d = f" = {a['Default']}" if a["Default"] else ""
                        n = f" — {clean(a['Notes'])}" if clean(a["Notes"]) else ""
                        lines.append(f"- `{vis} {a['Name']}: {a['Type']}{d}`{n}")
                lines.append("")
            ops = list(c.execute("select * from t_operation where Object_ID=? order by Pos", (oid,)))
            ops = [op for op in ops if not re.match(r"^(get|set|is)[A-Z]", op["Name"])
                   or clean(op["Notes"])]
            ops = [op for op in ops if not op["Name"].startswith("~")]
            if ops:
                lines.append("Operaciones:")
                for op in ops:
                    ps = [f"{p['Name']}: {p['Type']}" for p in c.execute(
                        "select * from t_operationparams where OperationID=? order by Pos", (op["OperationID"],))]
                    vis = {"Private": "-", "Public": "+", "Protected": "#"}.get(op["Scope"], "~")
                    ret = f": {op['Type']}" if op["Type"] and op["Name"] != o["Name"] else ""
                    n = f" — {clean(op['Notes'])}" if clean(op["Notes"]) else ""
                    lines.append(f"- `{vis} {op['Name']}({', '.join(ps)}){ret}`{n}")
                lines.append("")
            rels = []
            for x in c.execute("select * from t_connector where Start_Object_ID=? and Connector_Type in "
                               "('Association','Aggregation','Dependency')", (oid,)):
                if x["End_Object_ID"] not in objs:
                    continue
                tgt = objs[x["End_Object_ID"]]["Name"]
                card = f" [{x['DestCard']}]" if x["DestCard"] else ""
                agg = ""
                if x["Connector_Type"] == "Aggregation":
                    agg = " (composición)" if x["SubType"] == "Strong" else " (agregación)"
                rels.append(f"{x['Connector_Type']} → `{tgt}`{card}{agg}")
            if rels:
                lines.append("Relaciones: " + "; ".join(rels))
                lines.append("")
    open(os.path.join(out, "clases.md"), "w").write("\n".join(lines) + "\n")

    # ---------------- arquitectura.md ----------------
    arch = [o for o in objs.values() if re.search(r"3\.1\.1 Arqu?i?tectura del Sistema$", ppath(o["Package_ID"]))
            and o["Object_Type"] == "Component"]
    al = ["# Arquitectura del sistema (componentes del diagrama 3.1.1)", ""]
    for o in arch:
        al.append(f"- **{o['Name']}**: {clean(o['Note'])}")
    open(os.path.join(out, "arquitectura.md"), "w").write("\n".join(al) + "\n")

    # ---------------- casos-de-uso.md ----------------
    ul = ["# Casos de uso del sistema", ""]
    ucs = [o for o in objs.values() if o["Object_Type"] == "UseCase"
           and ppath(o["Package_ID"]).endswith("3.2.1 Casos de Uso")]
    for o in sorted(ucs, key=lambda r: [int(t) if t.isdigit() else t for t in re.split(r"(\d+)", r["Name"])]):
        ul.append(f"- **{o['Name']}**" + (f": {clean(o['Note'])}" if clean(o["Note"]) else ""))
    open(os.path.join(out, "casos-de-uso.md"), "w").write("\n".join(ul) + "\n")

    # ---------------- secuencias ----------------
    index = []
    for d in c.execute("select * from t_diagram where Diagram_Type='Sequence' order by Diagram_ID"):
        did = d["Diagram_ID"]
        m = re.search(r"(CUS-\d+)\s+(.*)", d["Name"])
        code, title = (m.group(1), m.group(2)) if m else (f"D{did}", d["Name"])
        dobjs = list(c.execute("select o.*, do.RectTop, do.RectBottom, do.RectLeft from t_diagramobjects do "
                               "join t_object o on o.Object_ID=do.Object_ID where do.Diagram_ID=?", (did,)))
        lifelines = sorted([o for o in dobjs if o["Object_Type"] in ("Sequence", "Actor")],
                           key=lambda r: r["RectLeft"])
        frags = []
        for o in dobjs:
            if o["Object_Type"] != "InteractionFragment":
                continue
            guards = []
            for x in c.execute("select Description from t_xref where Client=? and Name='Partitions'", (o["ea_guid"],)):
                for g in re.findall(r"@PAR;Name=(.*?);Size=(\d+);", x["Description"] or ""):
                    guards.append((g[0], int(g[1])))
            frags.append({"name": o["Name"], "op": FRAG.get(o["NType"], "?"), "top": o["RectTop"],
                          "bottom": o["RectBottom"], "guards": guards})
        events = []
        for x in c.execute("select * from t_connector where Connector_Type='Sequence' and DiagramID=?", (did,)):
            src = objs.get(x["Start_Object_ID"])
            dst = objs.get(x["End_Object_ID"])
            params = ""
            mm = re.search(r"paramsDlg=([^;]*)", x["PDATA2"] or "")
            if mm:
                params = mm.group(1)
            name = x["Name"] or ""
            is_ret = x["PDATA4"] == "1" or (x["PDATA3"] or "") == "Return"
            label = f"{name}({params})" if "(" not in name else name
            if is_ret or not mm:
                label = name if name else "retorno"
            events.append((x["PtStartY"], x["SeqNo"], "msg",
                           f"`{src['Name'] if src else '?'}` → `{dst['Name'] if dst else '?'}`: {label}"))
        for o in dobjs:
            if o["Object_Type"] == "InteractionOccurrence":
                events.append((o["RectTop"], 0, "ref", f"**ref** {o['Name']}" +
                               (f" — {clean(o['Note'])}" if clean(o["Note"]) else "")))
            elif o["Object_Type"] == "Note" and clean(o["Note"]):
                events.append((o["RectTop"], 0, "note", f"_Nota: {clean(o['Note'])}_"))
        events.sort(key=lambda e: (-e[0], e[1]))

        def enclosing(y):
            res = []
            for f in frags:
                if f["bottom"] <= y <= f["top"]:
                    g = ""
                    if f["guards"]:
                        # EA lista las particiones de abajo hacia arriba
                        acc = f["top"]
                        g = f["guards"][0][0]
                        for gname, size in reversed(f["guards"]):
                            if acc - size <= y <= acc:
                                g = gname
                                break
                            acc -= size
                    res.append((f["top"] - f["bottom"], f, g))
            res.sort(key=lambda t: -t[0])
            return [(f, g) for _, f, g in res]

        sl = [f"# {code} {title}", "", f"Diagrama de secuencia exportado de EA ({d['Name']}).", "",
              "## Participantes", ""]
        for o in lifelines:
            cls = objs[o["Classifier"]]["Name"] if o["Classifier"] in objs else ""
            sl.append(f"- `{o['Name']}`" + (f" : `{cls}`" if cls else f" ({o['Object_Type']})"))
        sl += ["", "## Mensajes", "",
               "Indentación = fragmento combinado que contiene el mensaje (`[op nombre | guarda]`).", ""]
        prev = []
        for y, seq, kind, text in events:
            enc = enclosing(y)
            key = [(id(f), g) for f, g in enc]
            for i, (f, g) in enumerate(enc):
                if i >= len(prev) or prev[i] != key[i]:
                    sl.append("  " * i + f"- **[{f['op']} {f['name']}" + (f" | {g}" if g else "") + "]**")
            num = f"{seq}. " if kind == "msg" else ""
            sl.append("  " * len(enc) + f"- {num}{text}")
            prev = key
        fname = f"{code}.md"
        open(os.path.join(out, "secuencias", fname), "w").write("\n".join(sl) + "\n")
        index.append(f"- [{code} {title}](secuencias/{fname})")

    rl = ["# Diseño del GIP en texto", "",
          "Exportado del modelo de Enterprise Architect (`ProyectoUML_XX.qea`). Claude Code no puede abrir el .qea; "
          "lee estos archivos. Si el modelo cambia, se regeneran con `python3 tool/export_qea.py <ruta.qea> docs/diseno`.", "",
          "- [Arquitectura](arquitectura.md)", "- [Clases de la Business Layer](clases.md)",
          "- [Casos de uso](casos-de-uso.md)", "", "## Diagramas de secuencia", ""] + index
    open(os.path.join(out, "README.md"), "w").write("\n".join(rl) + "\n")


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
