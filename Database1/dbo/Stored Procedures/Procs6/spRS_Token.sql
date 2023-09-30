CREATE PROCEDURE dbo.spRS_Token
@UID 	 INT = Null,
@Token 	 VARCHAR(255) = Null
AS
DECLARE @TempString 	 VARCHAR(255)
DECLARE @Position  	 INT
DECLARE @User_Id  	 INT
DECLARE @LANG_ID  	 INT
DECLARE @C  	  	  	 INT
DECLARE @PREFIX  	 INT
DECLARE @SUFFIX  	 INT
DECLARE @PASSWORD 	 VARCHAR(50)
DECLARE @USERNAME 	 VARCHAR(50)
Select @PREFIX = 12345
Select @SUFFIX = 12345
Create Table #TempTable(
 	 User_Id int,
 	 Username varchar(50),
 	 Password varchar(50),
 	 Lang_Id int,
 	 Token 	 varchar(255))
Select @Position = 1
Select @TempString = ''
If @Token Is Null
 	  	 goto EncodeUID
Else
 	  	 goto DecodeToken
EncodeUID:
 	 Print 'Encoding Token'
 	 If (select Value from user_Parameters where user_id = @UID and Parm_id = 8) Is Null
 	  	 Select @Lang_Id = 0
 	 Else
 	  	 select @Lang_Id = convert(int, Value) from user_Parameters where user_id = 51 and Parm_id = 8
 	 SELECT @Password = PASSWORD, @USERNAME = USERNAME FROM USERS Where User_Id = @UID
 	 Select @TempString = Convert(Varchar(5), @UID)
 	 Select @Token = ''
 	 While @Position <= DataLength(@TempString)
 	  	 Begin
 	  	  	 Select @C = convert(Int,(SubString(@TempString, @Position, 1)))
 	  	  	 Select @C = @C + 230
 	  	  	 Select @Token = @Token + Char(@C)
 	  	  	 Set @Position = @Position + 1
 	  	 End
 	 Insert Into #TempTable(User_Id, Lang_Id, Token, Password, Username)
 	  	  	  	  	 Values(@UID, @Lang_Id, @Token, @Password, @Username)
 	 Goto GetData
DecodeToken:
 	 Print 'Decoding Token'
 	 While @Position <= DataLength(@Token)
 	  	 Begin
 	  	  	 --If ASCII( SubString(@Token, @Position, 1)) < 230
 	  	  	 --return(0)
 	  	  	 --Select @C = CONVERT(Int,  ASCII( SubString(@Token, @Position, 1))    ) 	  	  	 
 	  	  	 Select @C = ASCII( SubString(@Token, @Position, 1))
 	  	  	 If @C < 230 Return(0)
 	  	  	 Select @C = @C - 230
 	  	  	 Select @TempString = @TempString +  Convert(varchar(1), @C)
 	  	  	 Set @Position = @Position + 1
 	  	 End
 	 If (select Value from user_Parameters where user_id = Convert(int, @TempString) and Parm_id = 8) Is Null
 	  	 Select @Lang_Id = 0
 	 Else
 	  	 select @Lang_Id = convert(int, Value) from user_Parameters where user_id = Convert(int, @TempString) and Parm_id = 8
 	  	 SELECT @Password = PASSWORD, @USERNAME = USERNAME FROM USERS Where User_Id = Convert(int, @TempString)
 	 Insert Into #TempTable(User_Id, Lang_Id, Token, Password, Username)
 	  	  	  	  	 Values(Convert(int, @TempString), @Lang_Id, @Token, @Password, @Username)
GetData:
Select * from #TempTable
Drop Table #TempTable
