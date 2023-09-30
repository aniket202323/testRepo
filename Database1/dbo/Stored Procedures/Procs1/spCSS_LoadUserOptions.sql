CREATE PROCEDURE dbo.spCSS_LoadUserOptions 
@User_Id int
AS
--Create Table #Options (OptionName nvarchar(50), OptionValue nvarchar(50))
--Insert Into #Options (OptionName, OptionValue) Values ('DefaultView','Converting Line #1')
--INSERT Into #Options
--Select * From #Options
--Drop Table #Options
/*
Select UPPER(Parm_Name) as OptionName, Value as OptionValue
    From User_Parameters u
    Join Parameters p on u.Parm_Id = p.Parm_Id
    Where User_Id = @User_Id
*/
Declare
  @UId int,
  @Name nvarchar(50),
  @Value nvarchar(50), 
  @Encrypted bit, 
  @OutputValue nVarChar(255)
Create Table #Parms (User_Id int, Parm_Name nvarchar(50), String_Value nvarchar(50) NULL, IsEncrypted bit)
Create Table #Parms2 (Parm_Name nvarchar(50), String_Value nvarchar(50) NULL)
Insert Into #Parms
  Select User_Id, Parm_Name, Value, IsEncrypted 
    From User_Parameters u
    Join Parameters p on p.Parm_Id = u.Parm_Id
    Where User_Id = @User_Id
--Site (App_Id = 0) and App parms/overrides
Declare ParmCursor INSENSITIVE CURSOR
  For (Select User_Id, Parm_Name, String_Value, IsEncrypted from #Parms)
  For Read Only
  Open ParmCursor  
ParmLoop1:
  Fetch Next From ParmCursor Into @UId, @Name, @Value, @Encrypted
  If (@@Fetch_Status = 0)
    Begin
      If @Encrypted = 1 
        Begin 
          execute spCmn_Encryption @Value, 'EncrYptoR', @UId , 0, @OutputValue output
          Select @Value = @OutputValue
        End
      Update #Parms2 Set String_Value = @Value Where Parm_Name = @Name
      If @@ROWCOUNT = 0 
        Insert Into #Parms2 (Parm_Name, String_Value) Values(@Name, @Value)
      Goto ParmLoop1
    End
Close ParmCursor
Deallocate ParmCursor
Select UPPER(Parm_Name) as Parm_Name, String_Value from #Parms2
