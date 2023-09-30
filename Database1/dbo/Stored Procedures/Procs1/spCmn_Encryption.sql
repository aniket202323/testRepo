CREATE PROCEDURE dbo.spCmn_Encryption
 	 @StringToEncrypt  VarChar(3000),
 	 @Password            VarChar(255),
 	 @AppId 	  	      Integer,
 	 @Encrypt                Bit,
 	 @Result 	      Varchar(3000)  output
 AS 
Declare @StringLength 	 Integer,
 	 @Counter 	 integer,
 	 @Char  	  	 integer,
 	 @A                     integer,
 	 @PWLen 	 Integer,
 	 @AscII 	  	 Integer,
 	 @LoopCounter   Integer,
 	 @RPaddedLength Integer,
 	 @LPaddedLength Integer
--Select @Password = Ltrim(Rtrim( @@ServerName + @Password))
IF @Encrypt = 0
  BEGIN
    Select @StringLength = datalength(@StringToEncrypt)
    Select @Counter = 1
    Select @Result =''
loop1:
    If @Counter <= @StringLength
 	 BEGIN
 	      IF  substring(@StringToEncrypt,@Counter,1) = '.' 
 	  	 BEGIN
 	  	   Select @Counter = @Counter + 1
 	  	   Select @Result = @Result + Char(Ascii(substring(@StringToEncrypt,@Counter,1)) - 65)
 	  	 END
 	      ELSE
 	      IF  substring(@StringToEncrypt,@Counter,1) = '-' 
 	  	 BEGIN
 	  	   Select @Counter = @Counter + 1
 	  	   Select @Result = @Result + Char(Ascii(substring(@StringToEncrypt,@Counter,1)) - 39)
 	  	 END
 	      ELSE
 	      IF  substring(@StringToEncrypt,@Counter,1) = '/' 
 	  	 BEGIN
 	  	   Select @Counter = @Counter + 1
 	  	   Select @Result = @Result + Char(Ascii(substring(@StringToEncrypt,@Counter,1)) - 13)
 	  	 END
 	      ELSE
 	      IF  substring(@StringToEncrypt,@Counter,1) = '>' 
 	  	 BEGIN
 	  	   Select @Counter = @Counter + 1
 	  	   Select @Result = @Result + Char(Ascii(substring(@StringToEncrypt,@Counter,1)) - 6)
 	  	 END
 	      ELSE
 	      IF  substring(@StringToEncrypt,@Counter,1) = '<' 
 	  	 BEGIN
 	  	   Select @Counter = @Counter + 1
 	  	   Select @Result = @Result + Char(Ascii(substring(@StringToEncrypt,@Counter,1)) + 25)
 	  	 END
 	      ELSE
                        Select @Result = @Result + substring(@StringToEncrypt,@Counter,1)
 	      Select @Counter = @Counter + 1
 	      GOTO Loop1
 	 END
 	 Select @LPaddedLength = datalength(Ltrim(Rtrim(Convert(VarChar(4), (@AppId * 8765) % 1000))))
 	 Select @RPaddedLength =  datalength(Ltrim(Rtrim(Convert(VarChar(4), (@AppId * 1234) % 1000)))) 
 	 If @LPaddedLength  + @RPaddedLength < @StringLength
     	  	 Select @StringToEncrypt = substring(ltrim(rtrim(@Result)),@LPaddedLength + 1,datalength(ltrim(rtrim(@Result)))-@LPaddedLength -@RPaddedLength)
 	 ELSE
     	  	 Select @StringToEncrypt = ltrim(rtrim(@Result))
   END
ELSE
  BEGIN
 	 Select @StringToEncrypt  = Ltrim(Rtrim(Convert(VarChar(4), (@AppId * 8765) % 1000) + @StringToEncrypt+ Ltrim(Rtrim(Convert(VarChar(4), (@AppId * 1234) % 1000)))))
  END
Select @Result = ''
IF  datalength(@Password) > @AppId
 	 Select @Counter = @AppId
ELSE
 	 Select @Counter = datalength(@Password)  % @AppId
Select @StringLength = datalength(@StringToEncrypt)
Select @PWLen = datalength(@Password)
Select @LoopCounter = 1
 Loop:
IF @LoopCounter <=  @StringLength 
 	 BEGIN
 	   select    @A = 0
 	    IF  @Counter % @PWLen = 0   Select @A = -1
 	    Select @Char = Ascii(Substring(@Password, ((@Counter % @PWLen) - @PWLen * @A),1))
 	    Select @AscII = ascii(substring(@StringToEncrypt,@LoopCounter,1)) ^ @char
 	    IF @Encrypt = 1
 	     BEGIN
                  IF @AscII < 26
 	  	 BEGIN
 	    	      Select @Result = @Result  +  '.' + Char(@AscII + 65)
 	  	 END
 	     ELSE
                  IF @AscII < 52
 	  	 BEGIN
 	    	      Select @Result = @Result  +  '-' + Char(@AscII + 39)
 	  	 END
 	     ELSE
                  IF @AscII < 65
 	  	 BEGIN
 	    	      Select @Result = @Result  +  '/' + Char(@AscII + 13)
 	  	 END
 	     ELSE
                  IF @AscII > 90 and  @AscII < 97
 	  	 BEGIN
 	    	      Select @Result = @Result  +  '>' + Char(@AscII + 6)
 	  	 END
 	     ELSE
                  IF @AscII > 122
 	  	 BEGIN
 	    	      Select @Result = @Result  +  '<' + Char(@AscII - 25)
 	  	 END
 	     ELSE
 	  	 BEGIN
 	    	      Select @Result = @Result +  Char(@AscII)
 	  	 END
 	   END
 	 ELSE
 	     Select @Result = @Result +  Char(@AscII)
-- 	    Select @Result = Substring(@Result,1,@Counter-1) +  Char(ascii(substring(@Result,@Counter,1)) ^ @char) + Substring(@Result,@Counter+1,@StringLength) 
 	    Select @LoopCounter =  @LoopCounter + 1
 	    GOTO Loop
 	 END
select @result = ltrim(rtrim(@Result))
