CREATE View dbo.Products
AS
select b.Prod_Id,b.Comment_Id,
Prod_Desc  = Case When @@options&(512) !=(0) THEN Coalesce(Prod_Desc,Prod_Desc_Global)
ELSE Coalesce(Prod_Desc_Global,Prod_Desc) END,
Prod_Desc_Global,
Prod_Desc_Local = Coalesce(Prod_Desc,Prod_Desc_Global),
Prod_Code = b.Prod_Code,  	  	  	  	   
b.Extended_Info,
b.Tag,
b.Event_Esignature_Level,
b.External_Link,
b.Is_Active_Product,
b.Is_Manufacturing_Product,
b.Is_Sales_Product,
b.Product_Change_Esignature_Level,
b.Product_Family_Id,
b.Use_Manufacturing_Product,
b.Alias_For_Product
from Products_Base b
-- Left Join Products_Aspect_MaterialDefinition a ON b.Prod_Id = a.Prod_Id 
-- Left Join MaterialDefinition c on c.MaterialDefinitionId = a.Origin1MaterialDefinitionId 

GO
CREATE TRIGGER [dbo].[ProductsViewIns]
 ON  [dbo].[Products]
  INSTEAD OF INSERT
  AS
 	 
IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
BEGIN
 	 SET NOCOUNT ON
 	 DECLARE @PAId 	 Int
 	 INSERT INTO Products_Base(Alias_For_Product,Comment_Id,Event_Esignature_Level,Extended_Info,External_Link,
 	  	  	  	  	 Is_Active_Product,Is_Manufacturing_Product,Is_Sales_Product,Prod_Code,Product_Change_Esignature_Level,
 	  	  	  	  	 Product_Family_Id,Tag,Use_Manufacturing_Product,Prod_Desc)
  	    	    Select  Alias_For_Product,Comment_Id,Event_Esignature_Level,Extended_Info,External_Link,
 	  	  	  	  	 Is_Active_Product,Is_Manufacturing_Product,Is_Sales_Product,Prod_Code,Product_Change_Esignature_Level,
 	  	  	  	  	 Product_Family_Id,Tag,Use_Manufacturing_Product,Prod_Desc
  	    	    From Inserted 
  	 SELECT @PAId = SCOPE_IDENTITY()
  	 IF (@PAId > 0) AND EXISTS(SELECT 1 FROM Site_Parameters WHERE Parm_Id = 87  and Value = 1 )
  	 INSERT INTO PlantAppsSOAPendingTasks(ActualId,TableId)
  	  	 VALUES(@PAId,23)
  	  	 
END
