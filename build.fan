using build

class EngineBuild : BuildPod
{
   new make()
   {
    podName   = "Engine"
    summary   = "A Gold Parser Engine"
		version   = Version("0.1")
		meta      = ["vcs.uri" : "https://github.com/elyashiv/GPEngine", "license.name" : "GPL"]
    depends   = ["sys 1.0+"]
    srcDirs   = [`fan/`, `test/`]
		resDirs   = [`res/`, `res/test-grammers/`]
		outPodDir = `./lib/fan/`
		outDocDir = `./doc/`
   }
}
