local fix_macos_build = [=====[
diff --git a/webpack.config.js b/webpack.config.js
index 9aff0cf..ff9c74e 100644
--- a/webpack.config.js
+++ b/webpack.config.js
@@ -1,6 +1,14 @@
 const path = require('path');
 const CopyPlugin = require('copy-webpack-plugin');

+const externals = {
+	vscode: 'commonjs vscode',
+};
+
+if (process.platform === "darwin") {
+	externals["fsevents"] = 'commonjs fsevents';
+}
+
 module.exports = {
 	context: path.resolve(__dirname, 'src'),
 	entry: {
@@ -19,9 +27,7 @@ module.exports = {
 			}
 		]
 	},
-	externals: {
-		vscode: 'commonjs vscode'
-	},
+	externals,
 	output: {
 		path: path.resolve(__dirname, 'dist'),
 		filename: '[name].bundle.js',
]=====]

return { fix_macos_build }
