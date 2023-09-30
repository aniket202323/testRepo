Create View dbo.Departments
AS
select c.Dept_Id,c.Comment_Id,
Dept_Desc  = Case When @@options&(512) !=(0) THEN  Coalesce(S95Id,Dept_Desc,Dept_Desc_Global)
 	  	  	  	   ELSE  Coalesce(Dept_Desc_Global,S95Id,Dept_Desc)
 	  	  	  	   END,
c.Extended_Info,c.Tag,c.Time_Zone,
Dept_Desc_Global,
Dept_Desc_Local = Coalesce(S95Id,Dept_Desc,Dept_Desc_Global)
from Departments_Base c  
Left Join PAEquipment_Aspect_SOAEquipment b On c.Dept_Id = b.Dept_Id
Left Join  Equipment a ON b.Origin1EquipmentId = a.EquipmentId
where   c.Dept_Id != 0

GO
CREATE TRIGGER [dbo].[DepartmentsViewIns]
 ON  [dbo].[Departments]
  INSTEAD OF INSERT
  AS
 	 
IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
BEGIN
 	 SET NOCOUNT ON
 	 DECLARE @PAId 	 Int
 	 INSERT INTO Departments_Base
  	    	    (Comment_Id,Extended_Info,Tag,Time_Zone,Dept_Desc)
  	    	    Select  Comment_Id,Extended_Info,Tag,Time_Zone,Dept_Desc
  	    	    From Inserted 
  	 SELECT @PAId = SCOPE_IDENTITY()
  IF (@PAId > 0) AND EXISTS(SELECT 1 FROM Site_Parameters WHERE Parm_Id = 87  and Value = 1 )
 	  	 INSERT INTO PlantAppsSOAPendingTasks(ActualId,TableId)
  	  	  	 VALUES(@PAId,17)
  	  	 
END
