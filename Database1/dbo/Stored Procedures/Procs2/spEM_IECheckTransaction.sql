CREATE PROCEDURE dbo.spEM_IECheckTransaction 
  @TransId 	  	 Int,
  @DoDelete 	  	 Int Output
  AS
Select @DoDelete = 1
If (Select Count(*) from Trans_Char_Links Where Trans_Id = @TransId ) > 0
 	 Select @DoDelete = 0
If (Select Count(*) from Trans_Characteristics Where Trans_Id = @TransId ) > 0
 	 Select @DoDelete = 0
If (Select Count(*) from Trans_Products Where Trans_Id = @TransId ) > 0
 	 Select @DoDelete = 0
If (Select Count(*) from Trans_Properties Where Trans_Id = @TransId ) > 0
 	 Select @DoDelete = 0
If (Select Count(*) from Trans_Variables Where Trans_Id = @TransId ) > 0
 	 Select @DoDelete = 0
