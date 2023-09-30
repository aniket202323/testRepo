Create Procedure dbo.spXLAEventGenealogy
 	 @EventNum 	 varchar(50),
 	 @EventId 	 int,
 	 @Relation 	 tinyint = NULL
 	 , @InTimeZone 	 varchar(200) = null
AS
Declare @DBTz varchar(100)
Select @DBTz = Value from Site_Parameters where Parm_id = 192
/* ---------------------------------
   Get Event ID
   ---------------------------------*/
If @EventId is Null
    BEGIN
 	 SELECT 	 @EventId = Event_Id
 	 FROM 	 Events 
 	 WHERE 	 Event_Num = @EventNum
    END
/* ---------------------------------
   Retrieve Data ...
   --------------------------------- */
If @Relation = 1 OR @Relation Is Null 	  	 -- Child
    BEGIN
 	 SELECT 	 ev.Event_Num, ev.Event_Id, [timestamp] = EV.timestamp at time zone @DBTz at time zone @InTimeZone, Production_Unit = pu.PU_Desc
 	       , Event_Type = 'Event' , Relationship = 'Child'
 	 FROM 	 Event_Components ec
 	 JOIN 	 Events ev ON ev.Event_Id = ec.Event_Id
 	 JOIN 	 Prod_Units pu ON pu.pu_id = ev.pu_id
 	 WHERE 	 ec.Source_Event_Id = @EventId
    END
Else 	  	  	  	  	  	 -- Parent
    BEGIN
 	 SELECT 	 ev.Event_Num, ev.Event_Id, [timestamp] = EV.timestamp at time zone @DBTz at time zone @InTimeZone, Production_Unit = pu.PU_Desc
 	       , Event_Type = 'Event', Relationship = 'Parent'
 	 FROM 	 Event_Components ec
 	 JOIN 	 Events ev on ev.Event_Id = ec.Source_Event_Id
 	 JOIN 	 Prod_Units pu on pu.pu_id = ev.pu_id
 	 WHERE 	 ec.Event_Id = @EventId
    END
