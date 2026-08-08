# _format-FM-calc-automator-workflow
An Automator workflow for OS X which creats a system service that visually formats FileMaker Pro calculations for easy readability, in any app in the system, even outside of FileMaker.

**Download:** grab the latest `_Format FM Calc.workflow.zip` from the [Releases page](https://github.com/kupietools/_format-FM-calc-automator-workflow/releases) — that's the ready-to-install package.

The `_Format FM Calc.workflow` folder in this repo's source tree is the actual editable source (a macOS Automator "package," which git and GitHub both handle as a plain folder of files — nothing about that affects how it behaves once it's on your Mac; Finder still recognizes and displays it as a package based on its `.workflow` extension, regardless of how it got there). The zip is a separate, generated distributable — it's what you should actually download and install, not the raw repo folder, and it's kept off to the side in Releases rather than the source tree so it can't go stale/out of sync with the source unnoticed the way it once did.

After unzipping, you will want to open the workflow in Automator and look at it before you add it to your Services folder. Just look at it so you see for yourself that it's innocent and does what it says, and there's nothing tricky about it. This is just a good habit, for security. Don't go adding things to your system because a stranger on github said you can. 

Place the unzipped `_Format FM Calc.workflow` in your /Users/[yourname]/Services folder to add "_Format FM Calc" to your Services menu (usually available either with a mouse right-click or as a submenu of the Application menu in most apps after the Apple menu in your menu bar.) Or, in some versions of MacOS, simply double-clocking on the unzipped workflow file will bring up a dialog box offering to install it. 

The original source code of the PERL script that does the formatting is visible as plain text once you open it within Automator too, if you want to see that. 

# Important note

One user has reported crashes and memory errors when using this system service in MacOS Sonoma with FileMaker 20. To my knowledge, nobody else has reported these issues, and I have not been able to reproduce them. An issue has been opened for this. Please be aware & prepared for this possibility when you use this, and back up any databases first in case of needing to do an improper shutdown. As with all Free & Open Source Software, use entirely at your own risk. In the event of trouble or issues, efforts at support are likely but not guaranteed. 

# Credits

This is substantially based on calculation_formatter.pl by Debi Fuchs <debi@aptworks.com> which was originally shared by Filemaker Inc in their Development Conventions PDF whitepaper in Nov. 2005, then heavily customized by me to make code clearer and keep up with changes in FM's calculation formatting beginning in 2012 forwards, as well as my own visual formatting. There are comments in the PERL code giving some info on my changes. 

# I am
Michael E. Kupietz, software engineering, consulting, & support for FileMaker Pro, Full-Stack Web, Desktop OS, & TradingView platforms  
https://kupietz.com (Business info)  
https://github.com/kupietools (Free software)  
https://michaelkupietz.com (Personal & creative showcase)  


