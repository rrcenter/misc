return {
	_id = "MainLayer",
	_type = "MainLayer",
	enableKeyPad = 1,
	height = "$fill",
	ignoreAnchor = 0,
	popOnBack = 1,
	width = "$fill",
	_children = {	   {
	      _id = "layerColor1",
	      _lock = 0,
	      _type = "cc.LayerColor",
	      color = "646464ff",
	      height = "$accuWin.h",
	      ignoreAnchor = 0,
	      width = "$accuWin.w",
	      scaleXY = {
	         x = "$scaleX",
	         y = "$scaleY"}},
	   {
	      _fold = false,
	      _id = "bottom",
	      _lock = 0,
	      _type = "cc.LayerGradient",
	      endOpacity = 255,
	      height = 112,
	      ignoreAnchor = 0,
	      startOpacity = 255,
	      width = "$fill",
	      anchor = {
	         x = 0,
	         y = 0},
	      endColor = {
	         a = 255,
	         b = 248,
	         g = 248,
	         r = 248},
	      scaleSize = {
	         h = "$minScale",
	         w = 1},
	      scaleXY = {
	         x = "$scaleX",
	         y = "$scaleY"},
	      startColor = {
	         a = 255,
	         b = 200,
	         g = 200,
	         r = 200},
	      vector = {
	         x = 0,
	         y = -1},
	      _children = {	         {
	            _fold = true,
	            _id = "label2",
	            _type = "cc.Label",
	            color = "1aad02",
	            enableWrap = true,
	            fontSize = 24,
	            height = 0,
	            ignoreAnchor = 1,
	            scaleX = "$minScale",
	            scaleY = "$minScale",
	            string = "@chats",
	            width = 0,
	            x = 80,
	            y = 22,
	            fontFile = {
	               en = "Arial"},
	            scaleXY = {
	               x = "$scaleX",
	               y = "$scaleY"}},
	         {
	            _fold = true,
	            _id = "label3",
	            _type = "cc.Label",
	            color = "1aad02",
	            enableWrap = true,
	            fontSize = 24,
	            height = 0,
	            ignoreAnchor = 1,
	            scaleX = "$minScale",
	            scaleY = "$minScale",
	            string = "@contacts",
	            width = 0,
	            x = 250,
	            y = 22,
	            fontFile = {
	               en = "Arial"},
	            scaleXY = {
	               x = "$scaleX",
	               y = "$scaleY"}},
	         {
	            _fold = true,
	            _id = "label4",
	            _type = "cc.Label",
	            color = "1aad02",
	            enableWrap = true,
	            fontSize = 24,
	            height = 0,
	            ignoreAnchor = 1,
	            scaleX = "$minScale",
	            scaleY = "$minScale",
	            string = "@discover",
	            width = 0,
	            x = 450,
	            y = 22,
	            fontFile = {
	               en = "Arial"},
	            scaleXY = {
	               x = "$scaleX",
	               y = "$scaleY"}},
	         {
	            _fold = true,
	            _id = "label5",
	            _type = "cc.Label",
	            color = "1aad02",
	            enableWrap = true,
	            fontSize = 24,
	            height = 0,
	            ignoreAnchor = 1,
	            scaleX = "$minScale",
	            scaleY = "$minScale",
	            string = "@me",
	            width = 0,
	            x = 600,
	            y = 22,
	            fontFile = {
	               en = "Arial"},
	            scaleXY = {
	               x = "$scaleX",
	               y = "$scaleY"}}}},
	   {
	      _fold = false,
	      _id = "top",
	      _lock = 0,
	      _type = "cc.LayerGradient",
	      endOpacity = 255,
	      height = 112,
	      ignoreAnchor = 1,
	      startOpacity = 255,
	      width = "$fill",
	      y = 1280,
	      anchor = {
	         x = 0,
	         y = 1},
	      endColor = {
	         a = 255,
	         b = 67,
	         g = 62,
	         r = 63},
	      scaleSize = {
	         h = "$minScale",
	         w = 1},
	      scaleXY = {
	         x = "$scaleX",
	         y = "$scaleY"},
	      startColor = {
	         a = 255,
	         b = 51,
	         g = 45,
	         r = 46},
	      vector = {
	         x = 0,
	         y = -1},
	      _children = {	         {
	            _id = "label1",
	            _type = "cc.Label",
	            enableWrap = true,
	            fontSize = 32,
	            height = 0,
	            ignoreAnchor = 1,
	            scaleX = "$minScale",
	            scaleY = "$minScale",
	            string = "@app_name",
	            width = 0,
	            x = 360,
	            y = 56,
	            fontFile = {
	               en = "Arial"},
	            scaleXY = {
	               x = "$scaleX",
	               y = "$scaleY"}}}},
	   {
	      _fold = true,
	      _id = "tableView1",
	      _type = "cc.TableView",
	      cellAtIndex = "&cellAtIndex",
	      cellNums = "&cellNumsOfTableView",
	      cellSizeForIndex = "&cellSizeForTable",
	      direction = 1,
	      height = 0,
	      ignoreAnchor = 0,
	      scaleX = "$xScale",
	      scaleY = "$xScale",
	      verticalFillOrder = 0,
	      width = 0,
	      y = 112,
	      anchor = {
	         x = 0,
	         y = 0},
	      scaleSize = {
	         h = "$minScale",
	         w = 1},
	      scaleXY = {
	         x = "$scaleX",
	         y = "$minScale"},
	      viewSize = {
	         height = 978,
	         width = 720}}}}