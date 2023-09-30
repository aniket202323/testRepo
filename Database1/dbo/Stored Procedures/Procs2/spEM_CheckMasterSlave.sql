CREATE PROCEDURE dbo.spEM_CheckMasterSlave
  @PU_Id       int,
  @Master_Unit int,
  @ErrorMessage nvarchar(150) Output
  AS
Declare @OldMaster_Unit Int
DECLARE @SlaveDesc 	 nvarchar(50)
Select @ErrorMessage = ''
Select @OldMaster_Unit = Master_Unit,@SlaveDesc = PU_Desc From Prod_Units where PU_Id = @PU_Id
If @OldMaster_Unit Is not Null and @Master_Unit Is Null --Slave to Master
  Begin
 	 If (Select Count(*) from timed_Event_Fault Where Source_PU_Id = @PU_Id) > 0
 	  	 Select @ErrorMessage = 'Faults exist for [' + @SlaveDesc + ']  - You cannot promote until the locations are corrected'
  End
Else If (@OldMaster_Unit Is not Null and @Master_Unit Is Not Null) and (@OldMaster_Unit <> @Master_Unit) --Slave to Slave
 	  	 Begin
 	  	  	 If (Select Count(*) from timed_Event_Fault Where Source_PU_Id = @PU_Id) > 0
 	  	  	  	 Select @ErrorMessage = 'Faults exist for [' + @SlaveDesc + ']  - You cannot change until locations are removed'
 	  	 End
Else If (@OldMaster_Unit Is Null and @Master_Unit Is Not Null) -- Master to Slave
 	  	 Begin
 	  	  	 If (Select Count(*) from Sheets Where master_Unit = @PU_Id) > 0
 	  	  	  	 Select @ErrorMessage = 'Displays are associated with  [' + @SlaveDesc + ']  - You cannot change until the Displays are corrected/removed'
 	  	  	 If (Select Count(*) from PU_Products Where PU_Id = @PU_Id) > 0
 	  	  	  	 Select @ErrorMessage = 'Products are associated with  [' + @SlaveDesc + ']  - You cannot change until products are removed'
 	  	  	 If (Select Count(*) from Event_Configuration Where PU_Id = @PU_Id) > 0
 	  	  	  	 Select @ErrorMessage = 'Events are configured for [' + @SlaveDesc + ']  - You cannot change until Events are removed'
 	  	      	 If (Select Count(*) from Prod_Xref Where PU_Id = @PU_Id) > 0
 	  	          	 Select @ErrorMessage = 'Product Cross References are configured for [' + @SlaveDesc + ']  - You cannot change until Product Cross References are removed'
 	  	 End
