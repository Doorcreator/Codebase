# To clean local html file by removing unwanted elements
# usage: from html_cleaner import CLEANER
import os, lxml.html, shutil
from html_frame_builder import FRAMER
from config_manager import CONFIG_MANAGER
class CLEANER():
    def __init__(self, inpath):
        self.inpath = inpath
        pre, suf = os.path.splitext(inpath)
        self.outpath = pre+"-output__"+suf
        self.tree = lxml.html.parse(inpath)
        self.root = self.tree.getroot()
        self.nodes = []
        self.EXSLT_NS = 'http://exslt.org/regular-expressions'
    def prune(self, parent, exprs):
    # To recursively remove all children of a parent node in a tree
    # parent: {lxml.html.HtmlElement} root node to prune from
    # exprs: {list} XPATH expressions to match target nodes
        for expr in exprs:
            for node in parent.xpath(expr, namespaces={'re': self.EXSLT_NS}):
                # print(f"Deleting node: {node.tag} {node.attrib}")
                node.drop_tree()
    def pick_out(self, parent, exprs):
    # To filter out unwanted nodes from a tree
    # parent: {lxml.html.HtmlElement} root node to filter against
    # exprs: {list} XPATH expressions to match target nodes
        for expr in exprs:
            m = parent.xpath(expr, namespaces={'re': self.EXSLT_NS})
            if m:
                self.nodes.append(m[0])
    def make_node(self, tag, text):
        node = lxml.html.etree.Element(tag)
        node.text = text
        return node
    def link_external_css(self, css_nam):
        css_path = f"{os.sep}".join([CONFIG_MANAGER().cwd, "settings", css_nam])
        dst_path = f"{os.sep}".join([os.path.dirname(self.inpath), css_nam])
        if not os.path.exists(dst_path):
            shutil.copy(css_path, dst_path)
        sty = self.make_node("link", "")
        sty.attrib["rel"] = "stylesheet"
        sty.attrib["href"] = f"./{css_nam}"
        return sty
    def weave(self, flt_exprs, sub_exprs):
    # flt_exprs: {list} XPATH expressions of elements to include in final html file
    # sub_exprs: {list} XPATH expressions of elements to exclude from final html file
    # plo_expr: {str} XPATH expression of element to determine page layout
        self.pick_out(self.root, flt_exprs)
        root = FRAMER(self.outpath).build_frame()
        parent = root.xpath('//div[@class="global_frame"]')[0]  
        ss = self.link_external_css("styles.css")
        parent.append(ss)
        with open(self.outpath, "wb") as f:
            for i in range(len(self.nodes)):
                node = self.nodes[i]
                if i == 0:
                    url = node.get("href")
                parent.append(node)
                # print(f"Writing node: {node.tag} {node.attrib}")
            eof_cmt = self.make_node("a", f"From: {url}")
            eof_cmt.attrib["href"] = url
            parent.append(eof_cmt)
            if sub_exprs != []:
                self.prune(parent, sub_exprs)
            f.write(lxml.html.tostring(parent))
        os.remove(self.inpath)
        print(f"Weave suscess: {self.inpath}")
# path = r'H:\NetdiskCache\ECO\tes.html'
# TO = CLEANER(path)
# TO.weave(*CONFIG_MANAGER().read_xpath())
# TO.weave([
                # "//link[re:test(@rel, 'canonical')]", # main url
                  # "//*[re:test(@class, 'css-1r2sn2n')]", # header
                  # "//*[re:test(@class, 'css-kpd7oo')]", # cover pic
                  # "//*[re:test(@class, 'css-1t4jlmt')]", # edition date
                  # "//*[re:test(@class, 'css-1a032gy')]", # body text
                  # ],
                  # [
                  # "//div[re:test(@class, 'css-m3y5rp')]", # audio player
                  # "//iframe[re:test(@src, 'youtube')]", # video player (youtube)
                  # "//div[re:test(@class, 'css-1902i5q')]", # [share] button
                  # "//style[re:test(@data-emotion, 'css.*')]", # style
                  # "//div[re:test(@class, 'css-l43203')]", # bottom garbage
                  # "//div[re:test(@class, 'css-1opcn9')]", # bottom garbage
                  # "//div[re:test(@class, 'css-1p7krpx')]", # bottom garbage
                  # "//div[re:test(@class, 'css-1ijq0b9')]", # bottom garbage
                  # ])
