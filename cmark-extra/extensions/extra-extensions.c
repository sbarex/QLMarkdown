//
//  extra-extensions.c
//  QLMarkdown
//
//  Created by Sbarex on 14/04/23.
//

#include "extra-extensions.h"

#include "cmark-gfm-core-extensions.h"
#include "registry.h"
#include "plugin.h"
#include "node.h"
#include "syntax_extension.h"
#include "table.h"

#include "mention.h"
#include "wikilink.h"
#include "hashtag.h"
// #include "checkbox.h"
#include "syntaxhighlight.h"
#include "inlineimage.h"
#include "emoji.h"
#include "heads.h"
#include "defl.h"
#include "admonition.h"
#include "highlight.h"
#include "math_ext.h"
#include "sub_ext.h"
#include "sup_ext.h"
#include "alert.h"

static int extra_extensions_registration(cmark_plugin *plugin) {
    cmark_plugin_register_syntax_extension(plugin, create_mention_extension());
    cmark_plugin_register_syntax_extension(plugin, create_wikilink_extension());
    cmark_plugin_register_syntax_extension(plugin, create_hashtag_extension());
    //cmark_plugin_register_syntax_extension(plugin, create_checkbox_extension());
    cmark_plugin_register_syntax_extension(plugin, create_inlineimage_extension());

    cmark_plugin_register_syntax_extension(plugin, create_syntaxhighlight_extension());

    cmark_plugin_register_syntax_extension(plugin, create_emoji_extension());
    cmark_plugin_register_syntax_extension(plugin, create_heads_extension());
    cmark_plugin_register_syntax_extension(plugin, create_definitionlist_extension());
    cmark_plugin_register_syntax_extension(plugin, create_admonition_extension());
    cmark_plugin_register_syntax_extension(plugin, create_highlight_extension());
    cmark_plugin_register_syntax_extension(plugin, create_math_extension());
    cmark_plugin_register_syntax_extension(plugin, create_sup_extension());
    cmark_plugin_register_syntax_extension(plugin, create_sub_extension());
    cmark_plugin_register_syntax_extension(plugin, create_alert_extension());
    return 1;
}

static cmark_can_contain_func table_can_contain;

// cmark-gfm's table cells accept only a fixed list of inline nodes, so sub, sup, highlight and math never formed inside a table.
static int table_can_contain_extra_inlines(cmark_syntax_extension *extension, cmark_node *node, cmark_node_type child_type) {
    if (node->type == CMARK_NODE_TABLE_CELL && CMARK_NODE_TYPE_INLINE_P(child_type)) {
        return 1;
    }
    return table_can_contain(extension, node, child_type);
}

void cmark_gfm_extra_extensions_ensure_registered(void) {
  static int registered = 0;

  if (!registered) {
    cmark_register_plugin(extra_extensions_registration);

    cmark_gfm_core_extensions_ensure_registered();
    cmark_syntax_extension *table = cmark_find_syntax_extension("table");
    // `registered` isn't thread-safe: never save our own wrapper as the original.
    cmark_can_contain_func can_contain = table->can_contain_func;
    if (can_contain != table_can_contain_extra_inlines) {
      table_can_contain = can_contain;
      cmark_syntax_extension_set_can_contain_func(table, table_can_contain_extra_inlines);
    }
    registered = 1;
  }
}
