;; @env setenv PATH
(setenv "PATH"
	(concat
	 "~/bin:"
	 "/opt/local/bin:"
	 "/opt/local/sbin:"
	 "/Users/mik8y/Documents/Developer/SDKs/android-sdk-mac_86:"
	 "/Applications/apache-tomcat-6.0.20:"
	 "/Applications/Emacs.app/Contents/MacOS/bin:"
	 "/Applications/Emacs.app/Contents/MacOS:"
	 (getenv "PATH")))
(setenv "JAVA_HOME"
        "/System/Library/Frameworks/JavaVM.framework/Versions/1.5.0/Home")
(setenv "CLASSPATH"
        "~/.emacs.d/plugins/ant-contrib/ant-contrib-1.0b3.jar")
(setenv "MAVEN_OPTS"
        "-Xmx1024m")
;; @env exec-path
(setq exec-path
      (append exec-path
	      '("/opt/local/bin"
		"/opt/local/sbin"
		"~/bin"
		"/Users/mik8y/Documents/Developer/SDKs/android-sdk-mac_86"
		"/Applications/apache-tomcat-6.0.20"
		)))

(provide '8macs-system)
