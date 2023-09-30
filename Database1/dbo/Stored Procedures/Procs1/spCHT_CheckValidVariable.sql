Create Procedure dbo.spCHT_CheckValidVariable 
 	 @ID int,
        @VarId int OUTPUT
AS
Select @VarId=0
Select @VarId= Var_Id from variables WITH (index(PK___3__12)) where var_id = @Id   
   And data_type_id in (1,2,4,6,7) 
