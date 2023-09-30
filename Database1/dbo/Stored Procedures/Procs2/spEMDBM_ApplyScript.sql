CREATE PROCEDURE dbo.spEMDBM_ApplyScript
 	 @GroupId Int
  AS
 	 Declare @Sql nvarchar(2000),@CmdId Int,@ST DateTime,@ET DateTime
 	 Declare Maint_Cursor Cursor 
 	  	 For Select Command,DBMC_Id
 	  	  	 From DB_Maintenance_Commands a
 	  	  	 Where DBMC_Group = @GroupId
 	  	  	 Order By DBMC_Group_Order
 	 Open Maint_Cursor
Maint_Cursor_Loop:
 	 Fetch Next From Maint_Cursor into @Sql,@CmdId
 	 If @@Fetch_Status = 0
 	  	 Begin
 	  	  	 Select @Sql = Replace(@Sql,'~','''')
 	  	  	 Select @ST = dbo.fnServer_CmnGetDate(getUTCdate())
 	  	  	 Execute  (@Sql)
 	  	  	 Select @ET = dbo.fnServer_CmnGetDate(getUTCdate())
 	  	  	 Update DB_Maintenance_Commands set Executed_On = @ST,Actual_Duration = datediff(Minute,@ST,@ET),Pending_Check = 0 Where DBMC_Id = @CmdId
 	  	  	 Goto Maint_Cursor_Loop 
 	  	 End
 	 Close Maint_Cursor
 	 Deallocate Maint_Cursor
