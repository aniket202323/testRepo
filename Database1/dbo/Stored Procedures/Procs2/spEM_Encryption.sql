CREATE PROCEDURE dbo.spEM_Encryption
 	 @StringToEncrypt  nvarchar(255),
 	 @Password            nvarchar(255),
 	 @Result 	      nvarchar(255)  output
 AS
Declare @StringLength 	 Integer,
 	 @Counter 	 integer,
 	 @Char  	  	 integer,
 	 @A                     integer,
 	 @PWLen 	 Integer
Select @Result = @StringToEncrypt
Select @StringLength = LEN(@StringToEncrypt)
Select @PWLen = LEN(@Password)
Select @Counter = 1
Loop:
IF @Counter <=  @StringLength 
 	 BEGIN
 	   select    @A = 0
 	    IF  @Counter % @PWLen = 0   Select @A = -1
 	    Select @Char = Ascii(Substring(@Password, ((@Counter % @PWLen) - @PWLen * @A),1))
 	    Select @Result = Substring(@Result,1,@Counter-1) +  Char(ascii(substring(@Result,@Counter,1)) ^ @char) + Substring(@Result,@Counter+1,@StringLength) 
 	    Select @Counter =  @Counter + 1
 	    GOTO Loop
 	 END
