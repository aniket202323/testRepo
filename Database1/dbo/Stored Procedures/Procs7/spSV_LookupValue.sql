Create Procedure dbo.spSV_LookupValue
@ID bigint,
@User_Id int,
@ResultNum int = 1,
@Value nvarchar(255) OUTPUT
AS
Declare @Insert_Id int
if @ResultNum = 1
 	 Begin
 	  	 Select @Value = Prod_Desc + ' - [' + Prod_Code + ']'
 	  	   From Products 
 	  	   Where Prod_Id = @Id
 	 End
else if @ResultNum = 3
 	 Begin
 	  	 Select @Value = BOM_Formulation_Desc
 	  	   From Bill_Of_Material_Formulation 
 	  	   Where BOM_Formulation_Id = @Id
 	 End
