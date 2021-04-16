import pysdif
from emlib import doctools
from typing import List, Callable
import os
import argparse

 
def findComponents(module, exclude=set()):
    names  = dir(module)
    funcnames = [n for n in names if n[0].islower() and not n.startswith("__") if n not in exclude]
    
    clsnames = [n for n in names if n[0].isupper()]
    components = [eval(f"{module.__name__}.{funcname}") for funcname in funcnames]
    funcs = [c for c in components if hasattr(c, '__module__')]
    modules = [c for c in components if not hasattr(c, '__module__')]

    classes = [eval(f"{module.__name__}.{clsname}") for clsname in clsnames]
    
    return funcs, classes, modules
    

def main(destfolder: str):
    exclude = {'logger'}

    clsfolder = os.path.join(destfolder, "classes")
    os.makedirs(clsfolder, exist_ok=True)

    renderConfig = doctools.RenderConfig(splitName=True, fmt="markdown", docfmt="markdown")

    clss = [pysdif.SdifFile, 
            pysdif._pysdif.FrameR, 
            pysdif._pysdif.Matrix, 
            pysdif._pysdif.FrameW, 
            # pysdif._pysdif.MatrixTypeDefinition
            ]
    
    clsnames = [doctools.fullname(cls).split(".")[-1] for cls in clss]
    clsNameToClass = {n:c for n, c in zip(clsnames, clss)}
    clsNameToPath = {n: f"classes/{n}.md" for i, n in enumerate(clsnames)}

    for clsname in clsnames:
        cls = clsNameToClass[clsname]
        path = clsNameToPath[clsname]
        docs = doctools.generateDocsForClass(cls, renderConfig=renderConfig, startLevel=1)
        docspath = os.path.join(destfolder, path)
        open(docspath, "w").write(docs)
    
    funcs, classes, modules = findComponents(pysdif, exclude=exclude)
    funcsdocstr = doctools.generateDocsForFunctions(funcs, renderConfig=renderConfig, title = "Functions", 
                                                    startLevel=2)



    # Layout

    sep = "\n----------\n"
    blocks = ["# Reference"]
    blocks.append(sep)
    blocks.append("## Classes")
    lines = [f"* [{clsname}]({path})" for clsname, path in clsNameToPath.items()]
    blocks.append("\n".join(lines))
    blocks.append(sep)
    blocks.append(funcsdocstr)
    
    s = "\n\n".join(blocks)
    referencemd = os.path.join(destfolder, "reference.md")
    open(referencemd, "w").write(s)

    funcs, classes, modules = findComponents(pysdif.tools, exclude=exclude)
    print(funcs)
    toolsdocs = doctools.generateDocsForFunctions(funcs, renderConfig=renderConfig, title = "Tools", 
                                                  startLevel=2)
    open(os.path.join(destfolder, "tools.md"), "w").write(toolsdocs)

    
if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--docs", default="docs")
    args = parser.parse_args()
    main(args.docs)
    os.system("mkdocs build")
