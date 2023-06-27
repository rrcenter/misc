return {
	_fold = true,
	_id = "errorReportDialog1",
	enableKeyPad = 1,
	height = "$fill",
	popOnBack = 1,
	touchEnabled = 1,
	width = "$fill",
	_children = {	   {
	      _fold = false,
	      _id = "dialogBg",
	      _type = "cc.LayerColor",
	      color = "f5f5f5ff",
	      height = 500,
	      ignoreAnchor = 1,
	      scaleX = "$minScale",
	      scaleY = "$minScale",
	      width = 900,
	      x = 640,
	      y = 360,
	      scaleXY = {
	         x = "$scaleX",
	         y = "$scaleY"},
	      _children = {	         {
	            _id = "layerGradient1",
	            _type = "cc.LayerGradient",
	            height = 50,
	            ignoreAnchor = 1,
	            width = 900,
	            x = 450,
	            y = 500,
	            anchor = {
	               x = 0.5,
	               y = 1},
	            endColor = {
	               a = 255,
	               b = 220,
	               g = 220,
	               r = 220},
	            startColor = {
	               a = 255,
	               b = 230,
	               g = 230,
	               r = 230},
	            _children = {	               {
	                  _id = "titleLabel",
	                  _type = "cc.Label",
	                  color = "141414",
	                  fontSize = 36,
	                  scaleX = 0.5,
	                  scaleY = 0.5,
	                  string = "Oops!",
	                  x = 450,
	                  y = 25},
	               {
	                  _id = "closeBtn",
	                  _type = "ZoomButton",
	                  scaleX = 0.7,
	                  scaleY = 0.7,
	                  x = 895,
	                  y = 26,
	                  anchor = {
	                     x = 1,
	                     y = 0.5},
	                  _children = {	                     {
	                        _id = "sprite1",
	                        _lock = 0,
	                        _type = "cc.Sprite",
	                        file = "gk/res/texture/close.png",
	                        x = 54,
	                        y = 40}}}}},
	         {
	            _id = "contentLabel",
	            _type = "cc.Label",
	            color = "141414",
	            fontSize = 32,
	            scaleX = 0.5,
	            scaleY = 0.5,
	            string = "label",
	            width = 1600,
	            x = 450,
	            y = 425,
	            anchor = {
	               x = 0.5,
	               y = 1}}}}}}