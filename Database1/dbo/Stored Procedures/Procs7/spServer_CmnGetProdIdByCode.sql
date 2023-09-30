CREATE PROCEDURE dbo.spServer_CmnGetProdIdByCode
@Prod_Code nVarChar(50),
@UseLike int,
@AutoCreate Int,
@PUId Int,
@DefaultProductFamily Int,
@ApplyToPath Int,
@CanReturnNull Int,
@Prod_Id Int OUTPUT
AS 
Declare
  @NumProds int,
 	 @Prod_Search nvarchar(50)
Select @Prod_Id = NULL
If (@UseLike = 0)
  Select @Prod_Id = Prod_Id From Products Where Prod_Code = @Prod_Code
Else
  Begin
    Select @Prod_Search = @Prod_Code + '%'
    Select @NumProds = Count(Prod_Id) From Products Where Prod_Code Like @Prod_Search
    If (@NumProds = 1)
      Select @Prod_Id = Prod_Id From Products Where Prod_Code Like @Prod_Search
    Else
      Select @Prod_Id = 1
  End
If (@AutoCreate = 1) and (@Prod_Id Is Null)
 	 Begin
 	  	 EXECUTE spEM_CreateProd  @Prod_Code,@Prod_Code,@DefaultProductFamily,6,0,@Prod_Id   OUTPUT
 	  	  	 if (@PUId > 0)
 	  	  	  	 INSERT INTO PU_PRODUCTS(PU_Id, Prod_Id) Values (@PUid, @Prod_Id) --add to unit
 	  	  	 if (@ApplyToPath = 1)
 	  	  	  	 Begin
 	  	  	  	  	 INSERT INTO prdexec_Path_Products (Path_Id,Prod_ID) --add to path
  	  	  	  	  	  	  	  	  	  	  	 (SELECT Path_Id,@Prod_Id FROM Prod_Units_Base pu JOIN prdexec_Paths pp ON  pp.PL_Id = pu.PL_Id WHERE PU_Id = @PUid)
 	  	  	  	 End
 	 End
Else
 	 Begin
 	  	 if (@PUId > 0) and (@Prod_Id Is not Null)
 	  	  	 Begin
 	  	  	  	 IF (Select  Count(*) From PU_PRODUCTS where PU_Id = @PUId and Prod_Id = @Prod_Id) = 0
 	  	  	  	  	 BEGIN
 	  	  	  	  	  	 INSERT INTO PU_PRODUCTS(PU_Id, Prod_Id) Values (@PUid, @Prod_Id) --add to unit
 	  	  	  	  	 END
 	  	  	 End
 	 End
If (@Prod_Id Is Null)
 	 Begin
 	  	 if (@CanReturnNull = 1)
 	  	  	 Select @Prod_Id = 0
 	  	 Else
 	  	  	 Select @Prod_Id = 1
 	 End
