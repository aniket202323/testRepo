Create Procedure dbo.spDBR_Set_Event_Routes
AS 	 
 	 declare @@RouteCount int
 	 select @@RouteCount = Count(rg_id) from cxs_route_group where rg_desc = 'ContentGenerator'
 	 
 	 if (@@RouteCount = 0)
 	 begin
 	  	 declare @@RouteGroupID int
 	  	 INSERT CXS_Route_Group VALUES('ContentGenerator')
 	  	 SELECT @@RouteGroupID = scope_identity()
 	  	 INSERT CXS_Leaf(Service_Id, RG_Id, Memory_List_Size, Permenant, Buffer_To_Disk) VALUES(52, @@RouteGroupID, 100, 1, 1)
 	  	 INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(@@RouteGroupID, 14) --Post Variable
 	  	 INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(@@RouteGroupID, 5)  --Post GRADE
 	  	 INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(@@RouteGroupID, 19) --Post PRODUCTION
 	 end
