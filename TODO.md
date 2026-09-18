Sep 8 2026 - currently breaks:

1. Turns
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

     JSONSetElement ( "" ;
[ "AssignTo" ; “<Name of Person to whom ticket should be assigned>” ; JSONSTRING ] ; //Optional. Leave out if you don’t need this
[ “CC” ; “<ListofEMailAddresses>” ; JSONSTRING ] ; //Optional
[ "File" ; Get ( FileName ) ; JSONSTRING ] ; 
[ "Script" ; Get ( ScriptName ) ; JSONSTRING ] ; //use literal text instead of function when in a server side script
[ “subject” ; “Text for Subject Line” ; JSONSTRING ] ; 
[ "Reason" ; "<Describe problem here>” ; JSONSTRING ] ; //This is the body of the email to IT Help
[ “MsgID” ; “<If you use Form Letter to create subject, reason, put ID here>” ; JSONSTRING ] ; 
[ “NoSafety” ; True ; JSONNUMBER ] //Optional, Dangerous, only use to disable safety valve feature if truly necessary
) // JSE


2. Says this has unbalanced quotes of parentheses. This is a completely valid Filemaker calculation:
```
     JSONSetElement ( "" ;
[ "AssignTo" ; “<Name of Person to whom ticket should be assigned>” ; JSONSTRING ] ; //Optional. Leave out if you don’t need this
[ “CC” ; “<ListofEMailAddresses>” ; JSONSTRING ] ; //Optional
[ "File" ; Get ( FileName ) ; JSONSTRING ] ; 
[ "Script" ; Get ( ScriptName ) ; JSONSTRING ] ; //use literal text instead of function when in a server side script
[ “subject” ; “Text for Subject Line” ; JSONSTRING ] ; 
[ "Reason" ; "<Describe problem here>” ; JSONSTRING ] ; //This is the body of the email to IT Help
[ “MsgID” ; “<If you use Form Letter to create subject, reason, put ID here>” ; JSONSTRING ] ; 
[ “NoSafety” ; True ; JSONNUMBER ] //Optional, Dangerous, only use to disable safety valve feature if truly necessary
) // JSE
```

3. This may be the same error as both above. This:

```JSONSetElement (
     "" ;
     //[ "AssignTo" ; "<Name of Person to whom ticket should be assigned>" ; JSONString ] ; //Optional. Leave out if you don’t need this
     [ "CC" ; "user@domain.org" ; JSONString ] ; //Optional 
     [ "File" ; Get ( FileName ) ; JSONString ] ;
     [ "Script" ; Get ( ScriptName ) ; JSONString ] ;
     //use literal text instead of function when in a server side script 
     [
          "subject" ;
          "PARES has no matching ParES file." ;
          JSONString
     ] ;
     [
          "Reason" ;
          "The find in around line 40 of the script '" & Get ( ScriptName ) &
          "' in file '" & Get ( FileName ) &
          "' returned 0 records. This may mean Cart #"&CART::_kp_cart&" has the wrong school year. This family's IF will likely be wrong .¶¶Local values:" &
          List ( "$_par: " & $_par; "right($_yr,2): "& Right($_yr;2)) ;
          JSONString
     ] //;
     /* This is the body of the email to IT Help [
          "MsgID" ;
          "<If you use Form Letter to create subject, reason, put ID here>" ;
          JSONString
     ]
      ; */
     //[ "NoSafety" ; True ; JSONNumber ] //Optional, Dangerous, only use to disable safety valve feature if truly necessary
)
// JSE
```

becomes this, which is totally wrong and a syntax error:

```
JSONSetElement (
     "" ;
     //[ "AssignTo" ; "<Name of Person to whom ticket should be assigned>" ; JSONString ] ; //Optional. Leave out if you don’t need this [ "CC" ; "user@domain.org" ; JSONString ] ;
     //Optional  [ "File" ; Get ( FileName ) ; JSONString ] ;
     [ "Script" ; Get ( ScriptName ) ; JSONString ] ;
     //use literal text instead of function when in a server side script  [
          "subject" ;
          "PARES has no matching ParES file." ;
          JSONString
     ] ;
     [
          "Reason" ;
          "The find in around line 40 of the script '" &
          Get ( ScriptName ) & "' in file '" & Get ( FileName ) &
          "' returned 0 records. This may mean Cart #" &
          CART::_kp_cart &
          " has the wrong school year. This family's IF will likely be wrong. ¶¶Local values:" &
          List (
               "$_par: " & $_par ;
               "right($_yr,2): " & Right ( $_yr ; 2 )
          ) ;
          JSONString
     ]
     //;
     /* This is the body of the email to IT Help [
          "MsgID" ;
          "<If you use Form Letter to create subject, reason, put ID here>" ;
          JSONString
     ]
      ; */
     //[ "NoSafety" ; True ; JSONNumber ] //Optional, Dangerous, only use to disable safety valve feature if truly necessary
)
// JSE
```