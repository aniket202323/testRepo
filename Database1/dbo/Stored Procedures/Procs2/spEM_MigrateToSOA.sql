CREATE   PROCEDURE dbo.spEM_MigrateToSOA
@NodeType nVarChar(2),
@Id int
AS
/*
Administrator node types
ac - PlantModel
dz - Department
ad - Line
ae - unit
ai - Product Folder
cn - Product Famliy
ag - variable
af - Variable Group
*/
IF @NodeType = 'ac' -- PlantModel
BEGIN
 	 INSERT INTO PlantAppsSOAPendingTasks(ActualId, TableId, WorkStarted)
 	  	 SELECT 	 a.Dept_Id, 17, 0 	 
 	  	 FROM 	 Departments a
 	  	 Left JOIN PAEquipment_Aspect_SOAEquipment b on a.Dept_Id = b.Dept_Id 
 	  	 Left JOIN  PlantAppsSOAPendingTasks d On d.ActualId = a.Dept_Id and d.WorkStarted <> 2  and d.TableId = 17
 	  	 WHERE 	 a.Dept_Id > 0 and b.Dept_Id is null and d.PendingTaskId is null
 	  	 
 	 INSERT INTO PlantAppsSOAPendingTasks(ActualId, TableId, WorkStarted)
 	  	 SELECT 	 a.PL_Id, 18, 0
 	  	 FROM 	 Prod_Lines  a
 	  	 Left JOIN PAEquipment_Aspect_SOAEquipment b on a.PL_Id = b.PL_Id 
 	  	 Left JOIN  PlantAppsSOAPendingTasks d On d.ActualId = a.PL_Id and d.WorkStarted <> 2  and d.TableId = 18
 	  	 WHERE 	 a.PL_Id > 0 and b.PL_Id is null and d.PendingTaskId is null
 	  	 
 	 INSERT INTO PlantAppsSOAPendingTasks(ActualId, TableId, WorkStarted)
 	  	 SELECT 	 a.pu_id, 43, 0
 	  	 FROM 	 Prod_Units a
 	  	 Left JOIN PAEquipment_Aspect_SOAEquipment b on a.pu_id = b.pu_id 
 	  	 Left JOIN  PlantAppsSOAPendingTasks d On d.ActualId = a.pu_id and d.WorkStarted <> 2  and d.TableId = 43
 	  	 WHERE 	 a.pu_id > 0 and b.pu_id is null and d.PendingTaskId is null
 	  	 
 	 INSERT INTO PlantAppsSOAPendingTasks(ActualId, TableId, WorkStarted)
 	  	 SELECT 	 a.Var_Id, 20, 0
 	  	 FROM 	 variables a
 	  	 Left JOIN Variables_Aspect_EquipmentProperty b on a.Var_Id = b.Var_Id  
 	  	 Left JOIN  PlantAppsSOAPendingTasks d On d.ActualId = a.Var_Id and d.WorkStarted <> 2  and d.TableId = 20
 	  	 WHERE 	 a.PU_Id > 0 and b.Var_Id is null and d.PendingTaskId is null
END
IF @NodeType = 'dz' -- Department
BEGIN
 	 INSERT INTO PlantAppsSOAPendingTasks(ActualId, TableId, WorkStarted)
 	  	 SELECT 	 a.Dept_Id, 17, 0 	 
 	  	 FROM 	 Departments a
 	  	 Left JOIN  PlantAppsSOAPendingTasks d On d.ActualId = a.Dept_Id and d.WorkStarted <> 2  and d.TableId = 17
 	  	 WHERE 	 a.Dept_Id = @Id and d.PendingTaskId is null
 	  	 
 	 INSERT INTO PlantAppsSOAPendingTasks(ActualId, TableId, WorkStarted)
 	  	 SELECT 	 a.PL_Id, 18, 0
 	  	 FROM 	 Prod_Lines  a
 	  	 Left JOIN  PlantAppsSOAPendingTasks d On d.ActualId = a.PL_Id and d.WorkStarted <> 2  and d.TableId = 18
 	  	 WHERE 	 a.Dept_Id = @Id and d.PendingTaskId is null
 	  	 
 	 INSERT INTO PlantAppsSOAPendingTasks(ActualId, TableId, WorkStarted)
 	  	 SELECT 	 a.pu_id, 43, 0
 	  	 FROM 	 Prod_Units a
 	  	 JOIN 	 Prod_Lines b on b.PL_Id = a.PL_Id 
 	  	 Left JOIN  PlantAppsSOAPendingTasks d On d.ActualId = a.pu_id and d.WorkStarted <> 2  and d.TableId = 43
 	  	 WHERE 	 b.Dept_Id = @Id and d.PendingTaskId is null
 	  	 
 	 INSERT INTO PlantAppsSOAPendingTasks(ActualId, TableId, WorkStarted)
 	  	 SELECT 	 a.Var_Id, 20, 0
 	  	 FROM 	 variables a
 	  	 Join Prod_Units b on b.PU_Id = a.PU_Id 
 	  	 JOIN 	 Prod_Lines c on c.PL_Id = b.PL_Id 
 	  	 Left JOIN  PlantAppsSOAPendingTasks d On d.ActualId = a.Var_Id and d.WorkStarted <> 2  and d.TableId = 20
 	  	 WHERE 	 c.Dept_Id = @Id and d.PendingTaskId is null
END
IF @NodeType = 'ad' -- Line
BEGIN
 	 INSERT INTO PlantAppsSOAPendingTasks(ActualId, TableId, WorkStarted)
 	  	 SELECT 	 a.PL_Id, 18, 0
 	  	 FROM 	 Prod_Lines  a
 	  	 Left JOIN  PlantAppsSOAPendingTasks d On d.ActualId = a.PL_Id and d.WorkStarted <> 2  and d.TableId = 18
 	  	 WHERE 	 a.PL_Id = @Id and d.PendingTaskId is null
 	  	 
 	 INSERT INTO PlantAppsSOAPendingTasks(ActualId, TableId, WorkStarted)
 	  	 SELECT 	 a.pu_id, 43, 0
 	  	 FROM 	 Prod_Units a
 	  	 JOIN 	 Prod_Lines b on b.PL_Id = a.PL_Id 
 	  	 Left JOIN  PlantAppsSOAPendingTasks d On d.ActualId = a.pu_id and d.WorkStarted <> 2  and d.TableId = 43
 	  	 WHERE 	 b.PL_Id = @Id and d.PendingTaskId is null
 	  	 
 	 INSERT INTO PlantAppsSOAPendingTasks(ActualId, TableId, WorkStarted)
 	  	 SELECT 	 a.Var_Id, 20, 0
 	  	 FROM 	 variables a
 	  	 Join Prod_Units b on b.PU_Id = a.PU_Id 
 	  	 JOIN 	 Prod_Lines c on c.PL_Id = b.PL_Id 
 	  	 Left JOIN  PlantAppsSOAPendingTasks d On d.ActualId = a.Var_Id and d.WorkStarted <> 2  and d.TableId = 20
 	  	 WHERE 	 c.PL_Id = @Id and d.PendingTaskId is null
END
IF @NodeType = 'ae' -- Unit
BEGIN
 	 INSERT INTO PlantAppsSOAPendingTasks(ActualId, TableId, WorkStarted)
 	  	 SELECT 	 a.pu_id, 43, 0
 	  	 FROM 	 Prod_Units a
 	  	 Left JOIN  PlantAppsSOAPendingTasks d On d.ActualId = a.pu_id and d.WorkStarted <> 2  and d.TableId = 43
 	  	 WHERE 	 a.PU_Id = @Id and d.PendingTaskId is null
 	  	 
 	 INSERT INTO PlantAppsSOAPendingTasks(ActualId, TableId, WorkStarted)
 	  	 SELECT 	 a.Var_Id, 20, 0
 	  	 FROM 	 variables a
 	  	 Join Prod_Units b on b.PU_Id = a.PU_Id 
 	  	 Left JOIN  PlantAppsSOAPendingTasks d On d.ActualId = a.Var_Id and d.WorkStarted <> 2  and d.TableId = 20
 	  	 WHERE 	 b.PU_Id = @Id and d.PendingTaskId is null
END
IF @NodeType = 'cn'  -- families
BEGIN
 	 INSERT INTO PlantAppsSOAPendingTasks(ActualId, TableId, WorkStarted)
 	  	 SELECT 	 a.Prod_Id, 23, 0 	 
 	  	 FROM 	 Products a
 	  	 Left Join Products_Aspect_MaterialDefinition b on b.Prod_Id = a.Prod_Id 
 	  	 Left JOIN  PlantAppsSOAPendingTasks d On d.ActualId = a.Prod_Id and d.WorkStarted <> 2  and d.TableId = 23
 	  	 WHERE 	 a.Product_Family_Id  = @Id and b.Prod_Id is null and d.PendingTaskId is null
END
IF @NodeType = 'ai'  -- material
BEGIN
 	 INSERT INTO PlantAppsSOAPendingTasks(ActualId, TableId, WorkStarted)
 	  	 SELECT 	 a.Prod_Id, 23, 0 	 
 	  	 FROM 	 Products a
 	  	 Left Join Products_Aspect_MaterialDefinition b on b.Prod_Id = a.Prod_Id 
 	  	 Left JOIN  PlantAppsSOAPendingTasks d On d.ActualId = a.Prod_Id and d.WorkStarted <> 2  and d.TableId = 23
 	  	 WHERE 	 b.Prod_Id is null and d.PendingTaskId is null
END
IF @NodeType = 'aw'  -- user
BEGIN
 	 /*IF NOT EXISTS(SELECT 1 FROM PlantAppsSOAPendingTasks WHERE  ActualId = @Id AND TableId = 36 and WorkStarted <> 2) and 
 	  	 EXISTS(SELECT 1 From USERS WHERE User_id = @Id and WindowsUserInfo is null or WindowsUserInfo = '') */
          IF NOT EXISTS(SELECT 1 FROM PlantAppsSOAPendingTasks WHERE  ActualId = @Id AND TableId = 36 and WorkStarted <> 2)
 	  	 BEGIN
 	  	  	 INSERT INTO PlantAppsSOAPendingTasks(ActualId, TableId, WorkStarted) VALUES( 	 @Id, 36, 0) 	 
 	  	  	 INSERT INTO PlantAppsSOAPendingTasks(ActualId, TableId, WorkStarted) VALUES( 	 @Id, -36, 0) 	 
 	  	 END
END
IF @NodeType = 'au'  -- user folder
BEGIN
 	 DECLARE @Users Table(UserId Int)
 	 INSERT INTO @Users(UserId)
 	  	 SELECT 	 a.User_Id
 	  	 FROM 	 Users a
 	  	 Left Join Users_Aspect_Person b on b.User_Id = a.user_Id
 	  	 Left JOIN  PlantAppsSOAPendingTasks d On d.ActualId = a.User_Id and d.WorkStarted <> 2  and d.TableId = 36
 	  	 Where Is_Role = 0 AND A.System = 0 and d.PendingTaskId is null --and (a.WindowsUserInfo is null or a.WindowsUserInfo = '')
 	 INSERT INTO PlantAppsSOAPendingTasks(ActualId, TableId, WorkStarted)
 	  	 SELECT 	 a.UserId, 36, 0 	 
 	  	 FROM 	 @Users a
 	 INSERT INTO PlantAppsSOAPendingTasks(ActualId, TableId, WorkStarted)
 	  	 SELECT 	 a.UserId, -36, 0 	 
 	  	 FROM 	 @Users a
END
IF @NodeType = 'ag'  -- Variables
BEGIN
 	 IF NOT EXISTS(SELECT 1 FROM PlantAppsSOAPendingTasks WHERE  ActualId = @Id AND TableId = 20 and WorkStarted <> 2)
 	  	 INSERT INTO PlantAppsSOAPendingTasks(ActualId, TableId, WorkStarted) 	  	 SELECT 	 @Id, 20, 0
END
IF @NodeType = 'af'  -- Variable Groups
BEGIN
 	 INSERT INTO PlantAppsSOAPendingTasks(ActualId, TableId, WorkStarted)
 	  	 SELECT 	 a.var_Id, 20, 0
 	  	  	 FROM 	 Variables a
 	  	  	 Join PU_Groups  b on b.PUG_Id = a.PUG_Id 
 	  	  	 LEFT JOIN Variables_Aspect_EquipmentProperty c on a.Var_Id = c.Var_Id
 	  	  	 Left JOIN  PlantAppsSOAPendingTasks d On d.ActualId = a.var_Id and d.WorkStarted <> 2 and d.TableId = 20
 	  	  	 WHERE 	 b.PUG_Id = @Id AND a.PU_Id > 0 AND c.Var_Id is null and d.PendingTaskId is null 
END
