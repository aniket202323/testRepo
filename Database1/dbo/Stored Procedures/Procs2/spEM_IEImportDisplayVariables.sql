CREATE  PROCEDURE dbo.spEM_IEImportDisplayVariables
@Sheet_Desc 	  	 nVarChar(100),
@PL_Desc 	  	 nVarChar(100),
@PU_Desc 	  	 nVarChar(100),
@Var_Desc 	  	 nVarChar(100),
@Title 	  	  	 nVarChar(100),
@sVar_Order 	  	 nVarChar(10),
@Activity_Order nVarChar(100),
@Execution_Start_Duration nVarChar(100),
@Target_Duration nVarChar(100),
@Activity_Alias nVarChar(100),
@AutoComplete_Duration nVarChar(100),
@External_URL_link nvarchar(510),
@Open_URL_Configuration int,
@Password nVarchar(100),
@User_Login nVarchar(100),
@User_Id 	  	 int
As
Declare @PL_Id int,
 	 @PU_Id int,
 	 @Sheet_Id int,
 	 @Existing_Var_Id int,
 	 @Existing_Var_Order int,
 	 @Existing_Title nVarChar(100),
 	 @Var_Id 	  	 int,
 	 @Var_Order 	 int
 	 
/* Initialization */
Select 	 @PL_Id 	  = Null,
 	 @PU_Id = Null,
 	 @Sheet_Id = Null,
 	 @Var_Id = 0,
 	 @Existing_Var_Id = Null,
 	 @Existing_Var_Order = Null,
 	 @Existing_Title = Null,
 	 @Var_Order = Null
Select @Sheet_Desc 	 = LTrim(RTrim(@Sheet_Desc))
Select @PL_Desc 	  	 = LTrim(RTrim(@PL_Desc))
Select @PU_Desc 	  	 = LTrim(RTrim(@PU_Desc))
Select @Var_Desc 	 = LTrim(RTrim(@Var_Desc))
--Select @Title 	  	 = LTrim(RTrim(@Title))
Select @sVar_Order 	 = LTrim(RTrim(@sVar_Order))
SELECT @Activity_Order   = LTRIM(RTRIM(@Activity_Order))
SELECT @Execution_Start_Duration  = LTRIM(RTRIM(@Execution_Start_Duration))
SELECT @Target_Duration = LTRIM(RTRIM(@Target_Duration))
SELECT @Activity_Alias = LTRIM(RTRIM(@Activity_Alias))
SELECT @AutoComplete_Duration  = LTRIM(RTRIM(@AutoComplete_Duration))
SELECT @External_URL_link  = LTRIM(RTRIM(@External_URL_link))
SELECT @Open_URL_Configuration  = LTRIM(RTRIM(@Open_URL_Configuration))
SELECT @Password  = LTRIM(RTRIM(@Password))
SELECT @User_Login = LTRIM(RTRIM(@User_Login))
If isnumeric(@sVar_Order) = 1
 	 Select @Var_Order = convert(Int,@sVar_Order)
If  @Sheet_Desc = '' or @Sheet_Desc IS NULL 
    BEGIN
      Select 'Failed - missing display description'
      Return(-100)
    END
/* Get Sheet_Id */
Select @Sheet_Id = Sheet_Id
From Sheets
Where Sheet_Desc =@Sheet_Desc
If @Sheet_Id Is Null
    BEGIN
      Select 'Failed - Unable to find display'
      Return(-100)
    END
/* Check Var Order */
If @Var_Order Is Null Or @Var_Order = 0
Begin
     Select @Var_Order = Max(Var_Order)+1
     From Sheet_Variables
     Where Sheet_Id = @Sheet_Id
End
ELSE
BEGIN
 	 Select @Existing_Var_Order = Var_Order
 	 From Sheet_Variables
 	 Where Sheet_Id = @Sheet_Id And Var_Order = @Var_Order
 	 If @Existing_Var_Order Is Not Null
 	 BEGIN
 	  	 UPDATE Sheet_Variables Set Var_Order = Var_Order + 1
 	  	 WHERE   Sheet_Id = @Sheet_Id And Var_Order >= @Existing_Var_Order
 	 END
END
If  @PL_Desc = '' or @PL_Desc is null
  Begin
 	 If @Title Is Null or len('*' + @Title + '*') = 2
 	   Begin
 	  	 Select 'Failed - Missing Title'
 	  	 Return(-100)
 	   End
 	 Else
 	   Begin
 	      
 	  	  Insert into Sheet_Variables (Sheet_Id, Title, Var_Order,Activity_Order,Execution_Start_Duration,Target_Duration,Activity_Alias,AutoComplete_Duration,External_URL_link,Open_URL_Configuration,[Password],User_Login) 
 	  	  SELECT @Sheet_Id, @Title, @Var_Order,@Activity_Order,@Execution_Start_Duration,@Target_Duration,@Activity_Alias,@AutoComplete_Duration,@External_URL_link,@Open_URL_Configuration,@Password,@User_Login
 	  	  WHERE NOT EXISTS (SELECT 1 FROM Sheet_Variables Where Sheet_Id = @Sheet_Id AND Title = @Title)
 	  	  UPDATE SV
 	  	  SET 
 	  	  Activity_Order = @Activity_Order,
 	  	  Execution_Start_Duration = @Execution_Start_Duration,
 	  	  Target_Duration = @Target_Duration,
 	  	  Activity_Alias = @Activity_Alias,
 	  	  AutoComplete_Duration = @AutoComplete_Duration,
 	  	  External_URL_link = @External_URL_link,
 	  	  Open_URL_Configuration = @Open_URL_Configuration,
 	  	  [Password] = @Password,
 	  	  User_Login = @User_Login
 	  	  FROM Sheet_Variables SV
 	  	  WHERE Sheet_Id = @Sheet_Id AND Title = @Title
 	   End
  End
Else
  Begin 	 /* Get PL_Id  */
 	 Select @PL_Id = PL_Id
 	 From Prod_Lines
 	 Where PL_Desc = @PL_Desc
  If @PL_Id Is Not Null
    Begin
     /* Get  PU_Id  */
     Select @PU_Id = PU_Id
     From Prod_Units
     Where PU_Desc = @PU_Desc And PL_Id = @PL_Id
     If @PU_Id Is Not Null
        Begin
          /* Get  Var_Id  */
          Select @Var_Id = Var_Id
          From Variables
          Where Var_Desc = @Var_Desc And PU_Id = @PU_Id
          If @Var_Id <> 0
            Begin 
              /* Check for existing Var_Id */
              Select @Existing_Var_Id = Var_Id
              From Sheet_Variables
              Where Sheet_Id = @Sheet_Id And Var_Id = @Var_Id
           /* Update Variables with Variable Id */
              If @Existing_Var_Id Is Null
                Insert into Sheet_Variables (Sheet_Id, Var_Id, Var_Order)
                Values (@Sheet_Id, @Var_Id, @Var_Order)
             End
 	  	   Else
 	  	  	 Begin
 	  	  	   Select 'Failed - variable not found'
 	  	  	   Return (-100)
 	  	  	 End
        End
 	   Else
 	  	 Begin
 	  	   Select 'Failed - Production unit not found'
 	  	   Return (-100)
 	  	 End
    End
  End
Return(0)
