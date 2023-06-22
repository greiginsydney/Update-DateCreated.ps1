<#
.SYNOPSIS
	This script copies an image's DateTaken value to its Created and LastModified times.

.DESCRIPTION
	This script copies an image's DateTaken value to its Created and LastModified times.
	You can run it with a single image, or pipe files or directories to it.
	The file will be skipped if it's not an image, opening it throws an error, or it doesn't have a DateTaken value

.NOTES
	Version				: 1.0
	Date				: TBA  2023
	Author				: Greig Sheridan
	See the credits at the bottom of the script

	Based on :  https://github.com/greiginsydney/Update-DateCreated.ps1
	Blog post:  https://greiginsydney.com/Update-DateCreated.ps1

	WISH-LIST / TODO:

	KNOWN ISSUES:

	Revision History 	:
				v1.0 TBA 2023
				

.LINK
	https://greiginsydney.com/Update-DateCreated.ps1 - also https://github.com/greiginsydney/Update-DateCreated.ps1


.EXAMPLE
	.\Update-DateCreated.ps1 IMG_1234.JPG

	Description
	-----------
	Copies the file IMG_1234.JPG's DateTaken value to its Created and LastModified times.

.EXAMPLE
	Get-ChildItem "IMG*.JPG" | .\Update-DateCreated.ps1

	Description
	-----------
	Makes the date changes to all files returned by the wildcard "IMG*.JPG"


.PARAMETER Image
	String. The image you want processed.


.PARAMETER Debug
	Switch. If present, outputs more debugging text when it hits an error

#>

[CmdletBinding(SupportsShouldProcess = $False)]
param(
	[parameter( ValueFromPipeLine = $true, ValueFromPipelineByPropertyName = $true, Position=0)]
	[string]$Image
)

begin
{
	$Global:Debug = $psboundparameters.debug.ispresent
	
	#--------------------------------
	# START FUNCTIONS ---------------
	#--------------------------------
	
	function Test-Image
	{
		[CmdletBinding()]
		param(
		[parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
			[ValidateNotNullOrEmpty()]
			[Alias('PSPath')]
			$Path
		)
		PROCESS
		{
			$knownImageExtensions = @( ".jpg", ".bmp", ".gif", ".tif", ".png" )
			$extension = [System.IO.Path]::GetExtension($Path.FullName)
			return $knownImageExtensions -contains $extension.ToLower()
		}
	}
	#--------------------------------
	#  END  FUNCTIONS ---------------
	#--------------------------------
	

}

process
{
	Get-ChildItem $Image | ForEach-Object `
	{
		if (!(Test-Image $_))
		{
			write-warning "$_ is an invalid file type. Skipping."
			continue
		}
		try
		{
			$bitmap = New-Object -TypeName System.Drawing.Bitmap -ArgumentList $_.FullName
			$propertyItem = $bitmap.GetPropertyItem(36867)
			if (!([string]::IsNullOrEmpty($propertyItem)))
			{
				$bytes = $propertyItem.Value
				$string = [System.Text.Encoding]::ASCII.GetString($bytes)
				try
				{
					$dateTime = [DateTime]::ParseExact($string,"yyyy:MM:dd HH:mm:ss`0",$Null)
					$bitmap.Dispose()
					$_.LastWriteTime = $dateTime
					$_.CreationTime = $dateTime
					write-output "$($_.Name) - $($dateTime.ToString())"
				}
				catch
				{
					write-warning "$($input.Name) threw at date conversion & update. Skipping."
					if ($debug)
					{
						$Global:error | Format-List -Property * -Force
					}
				}
			}
			else
			{
				write-warning "$Global_.Name has no DateTaken value. Skipping."
				continue
			}
		}
		catch
		{
			write-warning "$($input.Name) threw at opening the image. Skipping."
			if ($debug)
			{
				$Global:error | Format-List -Property * -Force
			}
		}
			if ($null -ne $bitmap) { $bitmap.Dispose() }
	}
}

end
{
}


# References:

# The meat of this script comes from this SO post:
# https://stackoverflow.com/a/71001306/13102734 TY Andrew Cleveland.

# https://devblogs.microsoft.com/scripting/psimaging-part-1-test-image/
# TY Dr Scripto. Crude but effective. See the above page if you want to improve this

# Powershell: How to access iterated object in catch-block
# https://stackoverflow.com/questions/71116115/powershell-how-to-access-iterated-object-in-catch-block
