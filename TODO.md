Sep 8 2026 - currently breaks:
```
//[ "CC" ; "<ListofEMailAddresses>" ; JSONString ] ; //Optional
[ "File" ; Get ( FileName ) ; JSONString ] ; 
[ "Script" ; Get ( ScriptName ) ; JSONString ] ; //use literal text instead of function when in a server side script
[ "subject" ; "stustyle_cart_parent_PARES has no matching ParES file." ; JSONString ] ; 
```
into
```
  //[ "CC" ; "<ListofEMailAddresses>" ; JSONString ] ; //Optional [ "File" ; Get ( FileName ) ; JSONString ] ;
     [ "Script" ; Get ( ScriptName ) ; JSONString ] ;
     //use literal text instead of function when in a server side script [
          "subject" ;
          "stustyle_cart_parent_PARES has no matching ParES file." ;
          JSONString
     ] ;
```
     which causes an error because live lines and a live [ have been moved into commented-out previous lines.