CREATE PROCEDURE dbo.spEM_IECreateTransaction
  @UserId 	  	 Int,
  @Trans_Id 	  	 Int Output,
  @Trans_Desc 	 nvarchar(50) Output
As
   If (Select Count(*) from Transactions) = 0
     Select @Trans_Desc = '<1> Import-Export'
   Else
     Select @Trans_Desc = '<' + Convert(nVarChar(10),Max(Trans_Id) + 1) + '> Import-Export' From Transactions 
   Execute spEM_CreateTransaction @Trans_Desc,Null,1,Null,@UserId,@Trans_Id OUTPUT
   If @Trans_Id Is Null
 	   Begin
 	  	 Return (-100)
 	   End
  Return (0)
