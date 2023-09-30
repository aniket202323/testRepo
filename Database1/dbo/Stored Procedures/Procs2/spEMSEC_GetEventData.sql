-- spEMSEC_GetEventData 10
CREATE Procedure dbo.spEMSEC_GetEventData
@PU_Id int
AS
--Only Scriptable Models
/*
210
211
212
304
800
SELECT ED_Model_Id,Model_Num,ModelDesc,* from ed_Models order by Model_Num
*/
DECLARE 	  	 @ET_Id 	  	  	 INT,
 	  	  	 @Count 	  	  	 INT,
 	  	  	 @Event_Models 	 INT
DECLARE @SupportedEventTypes Table (ET_Id Int)
INSERT INTO @SupportedEventTypes (ET_Id) 
 	 SELECT  ET_Id
 	 FROM event_Types
 	 WHERE Event_Models <> 0 --and ET_Id <> 29
INSERT  INTO @SupportedEventTypes( ET_Id)
 	  	  	 SELECT 16
INSERT  INTO @SupportedEventTypes( ET_Id)
 	  	  	 SELECT 17
INSERT  INTO @SupportedEventTypes( ET_Id)
 	  	  	 SELECT 18
SELECT e.ET_Id,Allow_Multiple_Active,Module_Id,SubTypes_Apply,ET_Desc,
 	 DefaultModel = Case When e.ET_Id = 2  Then  210
 	  	  	  	  	  	 When e.ET_Id = 3  Then  304
 	  	  	  	  	  	 When e.ET_Id = 1  Then  800
 	  	  	  	  	  	 When e.ET_Id = 30 Then  801
 	  	  	  	  	  	 When e.ET_Id = 14 Then  802
 	  	  	  	  	  	 When e.ET_Id = 4  Then  803
 	  	  	  	  	  	 When e.ET_Id = 19 Then  804
 	  	  	  	  	  	 When e.ET_Id = 6 Then  63
 	  	  	  	  	  	 When e.ET_Id = 7 Then  79
 	  	  	  	  	  	 When e.ET_Id = 8 Then  92
 	  	  	  	  	  	 When e.ET_Id = 10 Then  900
 	  	  	  	  	  	 When e.ET_Id = 21 Then  1054
 	  	  	  	  	  	 When e.ET_Id = 23 Then  94
 	  	  	  	  	  	 When e.ET_Id = 24 Then  95
 	  	  	  	  	  	 When e.ET_Id = 25 Then  88
 	  	  	  	  	  	 When e.ET_Id = 29 Then  5000
 	  	  	  	  	  	 ELSE 0
 	  	  	  	  	 END,
 	  	 AllowDataView = Isnull(e.AllowDataView,0),
 	  	 DefaultEdFieldId =  Case When e.ET_Id = 2  Then  187
 	  	  	  	  	  	  	 When e.ET_Id = 3  Then  2823
 	  	  	  	  	  	  	 When e.ET_Id = 1  Then  2831
 	  	  	  	  	  	  	 When e.ET_Id = 30 Then  2836
 	  	  	  	  	  	  	 When e.ET_Id = 14 Then  2840
 	  	  	  	  	  	  	 When e.ET_Id = 4  Then  2843
 	  	  	  	  	  	  	 ELSE 0
 	  	  	  	  	 END,
 	 Comment_Text = isnull(Comment_Text,et_Desc)
FROM Event_Types e
WHERE  e.ET_Id  IN (SELECT  ET_Id FROM @SupportedEventTypes)-- AND (SubTypes_Apply = 0 OR (SubTypes_Apply = 1 and event_subtype_desc IS NOT NULL))
Order by ET_Desc --,event_subtype_desc
SELECT e.EC_Id,
 	  	 e.Comment_Id,
 	  	 Debug = isnull(convert(int,e.Debug),0),
 	  	 EC_Desc = coalesce(e.EC_Desc,ed.Model_Desc,''),
 	  	 e.ED_Model_Id,
 	  	 Model_Num = Case When ed.Model_Num IS Null Then
 	  	  	  	  	  	  	 Case When e.ET_Id = 2  Then  210
 	  	  	  	  	  	  	  	 When e.ET_Id = 3  Then  304
 	  	  	  	  	  	  	  	 When e.ET_Id = 1  Then  800
 	  	  	  	  	  	  	  	 When e.ET_Id = 30 Then  801
 	  	  	  	  	  	  	  	 When e.ET_Id = 14 Then  802
 	  	  	  	  	  	  	  	 When e.ET_Id = 4  Then  803
 	  	  	  	  	  	  	  	 When e.ET_Id = 19 Then  804
 	  	  	  	  	  	  	  	 ELSE 0
 	  	  	  	  	  	  	 END
 	  	  	  	  	  	   ELSE ed.Model_Num
 	  	  	  	  	  	   END,
 	  	 e.ESignature_Level,
 	  	 e.ET_Id,
 	  	 Event_Subtype_Id = isnull(e.Event_Subtype_Id,0),
 	  	 e.Exclusions,
 	  	 e.Extended_Info,
 	  	 Is_Active = Case WHEN e.ED_Model_Id = 5400 Then isnull(e.Is_Calculation_Active,0) ELSE e.Is_Active END,
 	  	 Priority = IsNull(e.Priority,0),
 	  	 ET_Desc = coalesce(Et_Desc + '[' + Event_Subtype_Desc + ']',Et_Desc,'n/a'),
 	  	 SortOrder = Case When e.Is_Active is null then 1000
 	  	  	  	  	  	  When e.Is_Active = 0 then 1000
 	  	  	  	  	  	  When e.Is_Active = 2 then 1000
 	  	  	  	  	  	  Else e.Is_Active
 	  	  	  	    End,
 	  	 AllowDataView = Isnull(et.AllowDataView,0),
 	  	 DefaultEdFieldId = Case When ed.Model_Num IS Null Then
 	  	  	  	  	  	  	  	 Case When e.ET_Id = 2  Then  187
 	  	  	  	  	  	  	  	 When e.ET_Id = 3  Then  2823
 	  	  	  	  	  	  	  	 When e.ET_Id = 1  Then  2831
 	  	  	  	  	  	  	  	 When e.ET_Id = 30 Then  2836
 	  	  	  	  	  	  	  	 When e.ET_Id = 14 Then  2840
 	  	  	  	  	  	  	  	 When e.ET_Id = 4  Then  2843
 	  	  	  	  	  	  	  	 ELSE 0
 	  	  	  	  	  	  	 END
 	  	  	  	  	  	   ELSE Isnull(ef.ED_Field_Id,0)
 	  	  	  	  	 END,
 	  	 DerivedFrom = Case When ed.Model_Num IS Null Then
 	  	  	  	  	  	  	 Case When e.ET_Id = 2  Then  210
 	  	  	  	  	  	  	  	 When e.ET_Id = 3  Then  304
 	  	  	  	  	  	  	  	 When e.ET_Id = 1  Then  800
 	  	  	  	  	  	  	  	 When e.ET_Id = 30 Then  801
 	  	  	  	  	  	  	  	 When e.ET_Id = 14 Then  802
 	  	  	  	  	  	  	  	 When e.ET_Id = 4  Then  803
 	  	  	  	  	  	  	  	 When e.ET_Id = 19 Then  804
 	  	  	  	  	  	  	  	 ELSE 0
 	  	  	  	  	  	  	 END
 	  	  	  	  	  	   ELSE IsNull(ed.Derived_From, ed.Model_Num)
 	  	  	  	  	  	   END,
 	  	 AllowUpdate 	  	 = CASE WHEN e.ET_Id IN (16,17,18) THEN 0
 	  	  	  	  	  	  	  	 ELSE 1
 	  	  	  	  	  	   END,
/* All Fields after this are dynamically added to the listview*/
 	  	 [EC Id] = e.EC_Id,
 	  	 [Model Id] = e.ED_Model_Id,
 	  	 [Derived From] = ed.Derived_From
 	 FROM Event_Configuration e
 	 Left Join Ed_Models ed on ed.ED_Model_Id = e.ED_Model_Id
 	 LEFT JOIN ed_Fields ef ON e.ED_Model_Id = ef.ED_Model_Id and (ED_Field_Type_Id = 3 and Max_Instances > 400) 
 	 Left Join Event_Subtypes es on es.Event_Subtype_Id = e.Event_Subtype_Id
 	 Left Join event_Types et On et.ET_Id = e.ET_Id
 	 WHERE e.PU_Id = @PU_Id AND e.ET_Id  IN (SELECT  ET_Id FROM @SupportedEventTypes) 
 	 Order by SortOrder,e.Priority,e.EC_Id
 	 /* Attributes*/
 	 SELECT ED_Attribute_Id,Attribute_Desc,ModelMask = 2
 	 From ed_attributes
 	 Union
 	 SELECT ED_Attribute_Id = 3,Attribute_Desc = 'Current Event',ModelMask = 4
 	 /*Valid Sampling Types  ModelMask - 1=DownTime,2=Waste*/
 	 SELECT ST_Id,ST_Desc,ModelMask = Case WHEN ST_Id = 48 Then 2
 	  	  	  	  	  	  	  	  	  ELSE 	 3
 	  	  	  	  	  	  	  	  	 END
 	  	 From Sampling_type 
 	  	 Where ST_Id  in (2,12,14,48)
 	 Union
 	 SELECT ST_Id = Field_Id + 100 ,ST_Desc = Field_Desc,ModelMask = 4
 	  	 From Ed_FieldType_ValidValues  Where ED_Field_Type_Id = 66
/* Add Location Equipment Values */
 	 DECLARE @EQ Table(EQ_Id Int,EQ_Desc nvarchar(30))
 	 INSERT INTO @EQ (EQ_Id,EQ_Desc) VALUES (0,'Unavailable')
 	 INSERT INTO @EQ (EQ_Id,EQ_Desc) VALUES (1,'Down')
 	 INSERT INTO @EQ (EQ_Id,EQ_Desc) VALUES (2,'Starved')
 	 INSERT INTO @EQ (EQ_Id,EQ_Desc) VALUES (3,'Blocked')
 	 SELECT EQ_Id,EQ_Desc FROM @EQ
