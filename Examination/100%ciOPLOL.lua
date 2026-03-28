local args = {
	"handover"
}
game:GetService("ReplicatedStorage"):WaitForChild("Events"):WaitForChild("TachyonDialogue"):InvokeServer(unpack(args))