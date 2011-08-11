
// Dummy TestProvider used by Test-Helps.ps1

using System.Management.Automation;
using System.Management.Automation.Provider;
namespace Test
{
	[CmdletProvider("TestProvider", ProviderCapabilities.None)]
	public class AccessDBProvider : CmdletProvider
	{
	}
}
