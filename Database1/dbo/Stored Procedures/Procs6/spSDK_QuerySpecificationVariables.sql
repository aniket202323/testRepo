CREATE PROCEDURE dbo.spSDK_QuerySpecificationVariables
 	 @PropertyMask 	  	 nvarchar(50) = NULL,
 	 @SpecMask 	  	  	 nvarchar(50) = NULL,
 	 @UserId 	  	  	  	 INT 	  	  	 = NULL
AS
SET 	 @PropertyMask = 	 REPLACE(COALESCE(@PropertyMask, '*'), '*', '%')
SET 	 @PropertyMask = 	 REPLACE(REPLACE(@PropertyMask, '?', '_'), '[', '[[]')
SET 	 @SpecMask =  	  	 REPLACE(COALESCE(@SpecMask, '*'), '*', '%')
SET 	 @SpecMask =  	  	 REPLACE(REPLACE(@SpecMask, '?', '_'), '[', '[[]')
--Mask For Name Has Been Specified
SELECT 	 SpecificationId = s.Spec_Id,
 	  	  	 PropertyName = pp.Prop_Desc,
 	  	  	 SpecificationName = s.Spec_Desc,
 	  	  	 DataType = dt.Data_Type_Desc, 
 	  	  	 SpecPrecision = COALESCE(s.Spec_Precision, 0),
 	  	  	 EngineeringUnits = COALESCE(s.Eng_Units, ''),
 	  	  	 Tag = COALESCE(s.Tag, ''),
 	  	  	 ExtendedInfo = s.Extended_Info,
 	  	  	 CommentId = s.Comment_Id
 	 FROM 	  	  	  	  	 Product_Properties pp
 	  	  	 JOIN 	  	  	 Specifications s 	  	  	 ON 	  	 pp.Prop_Id = s.Prop_Id AND
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 pp.Prop_Desc LIKE @PropertyMask AND
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 s.Spec_Desc LIKE @SpecMask
 	  	  	 JOIN 	  	  	 Data_Type dt 	  	  	  	 ON 	  	 s.Data_Type_Id = dt.Data_Type_Id 
 	  	  	 LEFT JOIN 	 User_Security pps 	  	  	 ON 	  	 pp.Group_Id = pps.Group_Id
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND 	 pps.User_Id = @UserId
 	  	  	 LEFT JOIN 	 User_Security ss 	  	  	 ON 	  	 s.Group_Id = ss.Group_Id
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND 	 ss.User_Id = @UserId 	 
 	 WHERE COALESCE(pps.Access_Level, COALESCE(ss.Access_Level, 3)) >= 2
 	 ORDER BY 	 pp.Prop_Desc, s.Spec_Order
