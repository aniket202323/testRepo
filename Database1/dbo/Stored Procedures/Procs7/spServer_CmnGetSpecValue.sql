CREATE PROCEDURE dbo.spServer_CmnGetSpecValue
@VarId int,
@ProdId int,
@Mode int,
@Result nvarchar(50) OUTPUT
 AS
Select @Result = NULL
If (@Mode = 1)  Select @Result = U_Entry  	  	  	 From Var_Specs Where (Var_Id = @VarId) And (Prod_Id = @ProdId) And (Expiration_Date Is NULL)
If (@Mode = 2)  Select @Result = U_Reject  	  	  	 From Var_Specs Where (Var_Id = @VarId) And (Prod_Id = @ProdId) And (Expiration_Date Is NULL)
If (@Mode = 3)  Select @Result = U_Warning  	  	  	 From Var_Specs Where (Var_Id = @VarId) And (Prod_Id = @ProdId) And (Expiration_Date Is NULL)
If (@Mode = 4)  Select @Result = U_User  	  	  	 From Var_Specs Where (Var_Id = @VarId) And (Prod_Id = @ProdId) And (Expiration_Date Is NULL)
If (@Mode = 5)  Select @Result = Target  	  	  	 From Var_Specs Where (Var_Id = @VarId) And (Prod_Id = @ProdId) And (Expiration_Date Is NULL)
If (@Mode = 6)  Select @Result = L_User  	  	  	 From Var_Specs Where (Var_Id = @VarId) And (Prod_Id = @ProdId) And (Expiration_Date Is NULL)
If (@Mode = 7)  Select @Result = L_Warning  	  	  	 From Var_Specs Where (Var_Id = @VarId) And (Prod_Id = @ProdId) And (Expiration_Date Is NULL)
If (@Mode = 8)  Select @Result = L_Reject  	  	  	 From Var_Specs Where (Var_Id = @VarId) And (Prod_Id = @ProdId) And (Expiration_Date Is NULL)
If (@Mode = 9)  Select @Result = L_Entry  	  	  	 From Var_Specs Where (Var_Id = @VarId) And (Prod_Id = @ProdId) And (Expiration_Date Is NULL)
If (@Mode = 10) Select @Result = Convert(nVarChar(50),Test_Freq) 	 From Var_Specs Where (Var_Id = @VarId) And (Prod_Id = @ProdId) And (Expiration_Date Is NULL)
If (@Result Is NULL)
  Select @Result = ''
