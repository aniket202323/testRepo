Create Procedure dbo.spDS_GetElements
 @PatternId int,
 @RegionalServer Int = 0
AS
If @RegionalServer Is Null
 	 Select @RegionalServer = 0
IF @RegionalServer = 1
BEGIN
 	 DECLARE @CHT Table  (HeaderTag Int,Idx Int)
 	 Insert into @CHT(HeaderTag,Idx) Values (16538,1) -- 
 	 Insert into @CHT(HeaderTag,Idx) Values (16310,2) -- 
 	 Insert into @CHT(HeaderTag,Idx) Values (16313,3) -- 
 	 Insert into @CHT(HeaderTag,Idx) Values (16320,4) -- 
 	 Insert into @CHT(HeaderTag,Idx) Values (16539,5) -- 
 	 Insert into @CHT(HeaderTag,Idx) Values (16540,6) -- 
 	 Insert into @CHT(HeaderTag,Idx) Values (16541,7) -- 
 	 Insert into @CHT(HeaderTag,Idx) Values (16542,8) -- 
 	 Select HeaderTag From @CHT Order by Idx
 	 Select  [Tag] = PD.PP_Setup_Detail_Id, 
 	  	  	 [Order Line Id] = PD.Order_Line_Id, 
 	  	  	 [Number] = PD.Element_Number, 
 	  	  	 [Status] = PD.Element_Status, 
 	  	  	 [Product Code] = P.Prod_Code,
 	  	  	 [Target X] = PD.Target_Dimension_X, 
 	  	  	 [Target Y] = PD.Target_Dimension_Y, 
 	  	  	 [Target Z] = PD.Target_Dimension_Z, 
 	  	  	 [Target A] = PD.Target_Dimension_A 
 	 From Production_Setup_Detail PD
 	 Join Products P on P.Prod_Id = PD.Prod_Id
 	 Where PD.PP_Setup_Id = @PatternId
END
ELSE
BEGIN
  Select PD.PP_Setup_Detail_Id, PD.Order_Line_Id as 'Order Line Id', PD.Element_Number as 'Element Number', PD.Element_Status as 'Element Status', P.Prod_Code as 'Product',
         PD.Target_Dimension_X as 'Target Dimension X', PD.Target_Dimension_Y as 'Target Dimension Y', PD.Target_Dimension_Z as 'Target Dimension Z', 
         PD.Target_Dimension_A as 'Target Dimension A'
    From Production_Setup_Detail PD
      Join Products P on P.Prod_Id = PD.Prod_Id
       Where PD.PP_Setup_Id = @PatternId
END
