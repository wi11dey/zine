[CCode(cheader_filename="tree_sitter/api.h")]
namespace TreeSitter {
	[CCode(cname="TSLanguage")]
	[Compact]
	public class Language {}

	[CCode(cname="TSTree", )]
	[Compact]
	public class Node {}

	[CCode(cname="TSTree", free_function="ts_tree_delete")]
	[Compact]
	public class Tree {}

	[CCode(cname="TSParser", cprefix="ts_parser_", free_function="ts_parser_delete")]
	[Compact]
	public class Parser {
		[CCode(cname="ts_parser_new")]
		public Parser();

		public void set_langage(Language language);

		public Tree parse_string(string source);
	}
}