using build

class EngineBuild : BuildPod
{
   new make()
   {
    podName = "Engine"
    summary = "A Gold Parser Engine"
    depends = ["sys 1.0+"]
    srcDirs = [`fan/`, `test/`]
		resDirs = [`res/`, `res/test-grammers/`]
		outPodDir = `./lib/fan/`
		outDocDir = `./doc/`
   }
}
