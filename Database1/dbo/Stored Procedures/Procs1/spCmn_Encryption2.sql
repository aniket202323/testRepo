CREATE PROCEDURE dbo.spCmn_Encryption2
 	 @StringToEncrypt  VarChar(3000),
 	 @Password         VarChar(255),
 	 @Encrypt          Bit,
 	 @Result 	  	  	   Varchar(3000) output
 AS 
Declare @StringLength 	 Int,
 	  	 @Counter 	  	 Int,
 	  	 @Char  	  	  	 Int,
 	  	 @A              Int,
 	  	 @PWLen 	  	  	 Int,
 	  	 @AscII 	  	  	 Int,
 	  	 @LoopCounter 	 Int
Select @Password = Ltrim(Rtrim(@Password))
Select @Result = ''
Select @Counter = datalength(@Password)
Select @StringLength = datalength(@StringToEncrypt)
Select @PWLen = datalength(@Password)
Select @LoopCounter = 1
 Loop:
IF @LoopCounter <=  @StringLength
 	 BEGIN
 	    Select @Char = Ascii(Substring(@Password, ((@LoopCounter % @PWLen)+ 1),1))
 	    Select @AscII = ascii(substring(@StringToEncrypt,@LoopCounter,1)) ^ @char
 	  	 If @AscII = 0 Select @AscII = ascii(substring(@StringToEncrypt,@LoopCounter,1))
 	    IF @Encrypt = 1
   	      Select @Result = @Result + Char(@AscII)
 	    ELSE
 	     Select @Result = @Result + Char(@AscII)
 	    Select @LoopCounter =  @LoopCounter + 1
 	    GOTO Loop
 	 END
