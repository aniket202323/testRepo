Create View dbo.Prod_Lines
AS
select a.PL_Id,Comment_Id,a.Dept_Id,Extended_Info,External_Link,Group_Id,
 	  	 PL_Desc = Case When @@options&(512) !=(0) THEN Coalesce(S95Id,PL_Desc,PL_Desc_Global)
 	  	  	  	   ELSE  Coalesce(PL_Desc_Global,S95Id,PL_Desc)
 	  	  	  	   END,
 	  	 Tag,User_Defined1,User_Defined2,User_Defined3,OverView_Positions,PL_Desc_Global,
 	  	 PL_Desc_Local = Coalesce(S95Id,PL_Desc,PL_Desc_Global),
 	  	 a.LineOEEMode
From Prod_Lines_base a
Left Join PAEquipment_Aspect_SOAEquipment b On a.PL_Id = b.PL_Id
Left Join Equipment c on  b.Origin1EquipmentId = c.EquipmentId
where  a.pl_id != 0

GO
CREATE TRIGGER [dbo].[ProdLinesViewIns]
 ON  [dbo].[Prod_Lines]
  INSTEAD OF INSERT
  AS
 	 
IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
BEGIN
 	 SET NOCOUNT ON
 	 DECLARE @PAId 	 Int
 	 INSERT INTO Prod_Lines_Base(Comment_Id,Dept_Id,Extended_Info,External_Link,Group_Id,
 	  	  	  	  	  	  	 PL_Desc,Tag,User_Defined1,User_Defined2,User_Defined3,
 	  	  	  	  	  	  	 OverView_Positions,LineOEEMode)
  	  	 SELECT  Comment_Id,Dept_Id,Extended_Info,External_Link,Group_Id,
  	  	  	  	 PL_Desc,Tag,User_Defined1,User_Defined2,User_Defined3,
  	  	  	  	 OverView_Positions,LineOEEMode
  	    	    From Inserted 
  	 SELECT @PAId = SCOPE_IDENTITY()
  	 IF (@PAId > 0) AND EXISTS(SELECT 1 FROM Site_Parameters WHERE Parm_Id = 87  and Value = 1 )
  	  	 INSERT INTO PlantAppsSOAPendingTasks(ActualId,TableId) 	 VALUES(@PAId,18)
  	  	 
END
