CREATE PROCEDURE dbo.spEM_BOMSaveFormulationProduct
 	 @form int,
 	 @prod int,
 	 @unit int
AS
 	 if @prod is null
 	  	 delete from 
 	  	  	 Bill_Of_Material_Product 
 	  	 where
 	  	  	 BOM_Formulation_Id=@form
 	 else if not exists(select * from Bill_Of_Material_Product where Prod_Id=@prod and BOM_Formulation_Id=@form and (@unit=PU_Id or (@unit is null and PU_Id is null)))
 	  	 insert into 
 	  	  	 Bill_Of_Material_Product 
 	  	  	 (Prod_Id,BOM_Formulation_Id,PU_Id) 
 	  	 values 
 	  	  	 (@prod,@form,@unit)
