 /*  
Stored Procedure: spLocal_RptTranslations  
Author:   Matthew Wells (MSI)  
Date Created:  01/14/04  
  
Description:  
===========  
This procedure takes a large number of text inputs, translates them and returns  
them in a result set of the same number of inputs.  
  
Change Date  Rev#  Who What  
===========  ====  ==== =====  
01/14/04   1.00  MKW Added comment.  
2004-MAY-12  2.00  FLD Changed the texts' size from varchar(50) to varchar(100).  
03/31/05   3.00  JSJ Added the owner name to object references.  
*/  
  
CREATE  PROCEDURE dbo.spLocal_RptTranslations  
@UserName varchar(30),  
@Text01  varchar(100) = NULL,  
@Text02  varchar(100) = NULL,  
@Text03  varchar(100) = NULL,  
@Text04  varchar(100) = NULL,  
@Text05  varchar(100) = NULL,  
@Text06  varchar(100) = NULL,  
@Text07  varchar(100) = NULL,  
@Text08  varchar(100) = NULL,  
@Text09  varchar(100) = NULL,  
@Text10  varchar(100) = NULL,  
@Text11  varchar(100) = NULL,  
@Text12  varchar(100) = NULL,  
@Text13  varchar(100) = NULL,  
@Text14  varchar(100) = NULL,  
@Text15  varchar(100) = NULL,  
@Text16  varchar(100) = NULL,  
@Text17  varchar(100) = NULL,  
@Text18  varchar(100) = NULL,  
@Text19  varchar(100) = NULL,  
@Text20  varchar(100) = NULL,  
@Text21  varchar(100) = NULL,  
@Text22  varchar(100) = NULL,  
@Text23  varchar(100) = NULL,  
@Text24  varchar(100) = NULL,  
@Text25  varchar(100) = NULL,  
@Text26  varchar(100) = NULL,  
@Text27  varchar(100) = NULL,  
@Text28  varchar(100) = NULL,  
@Text29  varchar(100) = NULL,  
@Text30  varchar(100) = NULL,  
@Text31  varchar(100) = NULL,  
@Text32  varchar(100) = NULL,  
@Text33  varchar(100) = NULL,  
@Text34  varchar(100) = NULL,  
@Text35  varchar(100) = NULL,  
@Text36  varchar(100) = NULL,  
@Text37  varchar(100) = NULL,  
@Text38  varchar(100) = NULL,  
@Text39  varchar(100) = NULL,  
@Text40  varchar(100) = NULL,  
@Text41  varchar(100) = NULL,  
@Text42  varchar(100) = NULL,  
@Text43  varchar(100) = NULL,  
@Text44  varchar(100) = NULL,  
@Text45  varchar(100) = NULL,  
@Text46  varchar(100) = NULL,  
@Text47  varchar(100) = NULL,  
@Text48  varchar(100) = NULL,  
@Text49  varchar(100) = NULL,  
@Text50  varchar(100) = NULL,  
@Text51  varchar(100) = NULL,  
@Text52  varchar(100) = NULL,  
@Text53  varchar(100) = NULL,  
@Text54  varchar(100) = NULL,  
@Text55  varchar(100) = NULL,  
@Text56  varchar(100) = NULL,  
@Text57  varchar(100) = NULL,  
@Text58  varchar(100) = NULL,  
@Text59  varchar(100) = NULL,  
@Text60  varchar(100) = NULL,  
@Text61  varchar(100) = NULL,  
@Text62  varchar(100) = NULL,  
@Text63  varchar(100) = NULL,  
@Text64  varchar(100) = NULL,  
@Text65  varchar(100) = NULL,  
@Text66  varchar(100) = NULL,  
@Text67  varchar(100) = NULL,  
@Text68  varchar(100) = NULL,  
@Text69  varchar(100) = NULL,  
@Text70  varchar(100) = NULL,  
@Text71  varchar(100) = NULL,  
@Text72  varchar(100) = NULL,  
@Text73  varchar(100) = NULL,  
@Text74  varchar(100) = NULL,  
@Text75  varchar(100) = NULL,  
@Text76  varchar(100) = NULL,  
@Text77  varchar(100) = NULL,  
@Text78  varchar(100) = NULL,  
@Text79  varchar(100) = NULL,  
@Text80  varchar(100) = NULL  
AS  
  
-------------------------------------------------------------------------------  
-- Declarations  
-------------------------------------------------------------------------------  
DECLARE @LanguageId  int,  
 @LanguageParmId  int,  
 @UserId   int  
  
DECLARE @Text TABLE ( TextId  int IDENTITY,  
   TextValue varchar(100))  
  
-------------------------------------------------------------------------------  
-- Initialization  
-------------------------------------------------------------------------------  
INSERT @Text (TextValue) VALUES (@Text01)  
INSERT @Text (TextValue) VALUES (@Text02)  
INSERT @Text (TextValue) VALUES (@Text03)  
INSERT @Text (TextValue) VALUES (@Text04)  
INSERT @Text (TextValue) VALUES (@Text05)  
INSERT @Text (TextValue) VALUES (@Text06)  
INSERT @Text (TextValue) VALUES (@Text07)  
INSERT @Text (TextValue) VALUES (@Text08)  
INSERT @Text (TextValue) VALUES (@Text09)  
INSERT @Text (TextValue) VALUES (@Text10)  
INSERT @Text (TextValue) VALUES (@Text11)  
INSERT @Text (TextValue) VALUES (@Text12)  
INSERT @Text (TextValue) VALUES (@Text13)  
INSERT @Text (TextValue) VALUES (@Text14)  
INSERT @Text (TextValue) VALUES (@Text15)  
INSERT @Text (TextValue) VALUES (@Text16)  
INSERT @Text (TextValue) VALUES (@Text17)  
INSERT @Text (TextValue) VALUES (@Text18)  
INSERT @Text (TextValue) VALUES (@Text19)  
INSERT @Text (TextValue) VALUES (@Text20)  
INSERT @Text (TextValue) VALUES (@Text21)  
INSERT @Text (TextValue) VALUES (@Text22)  
INSERT @Text (TextValue) VALUES (@Text23)  
INSERT @Text (TextValue) VALUES (@Text24)  
INSERT @Text (TextValue) VALUES (@Text25)  
INSERT @Text (TextValue) VALUES (@Text26)  
INSERT @Text (TextValue) VALUES (@Text27)  
INSERT @Text (TextValue) VALUES (@Text28)  
INSERT @Text (TextValue) VALUES (@Text29)  
INSERT @Text (TextValue) VALUES (@Text30)  
INSERT @Text (TextValue) VALUES (@Text31)  
INSERT @Text (TextValue) VALUES (@Text32)  
INSERT @Text (TextValue) VALUES (@Text33)  
INSERT @Text (TextValue) VALUES (@Text34)  
INSERT @Text (TextValue) VALUES (@Text35)  
INSERT @Text (TextValue) VALUES (@Text36)  
INSERT @Text (TextValue) VALUES (@Text37)  
INSERT @Text (TextValue) VALUES (@Text38)  
INSERT @Text (TextValue) VALUES (@Text39)  
INSERT @Text (TextValue) VALUES (@Text40)  
INSERT @Text (TextValue) VALUES (@Text41)  
INSERT @Text (TextValue) VALUES (@Text42)  
INSERT @Text (TextValue) VALUES (@Text43)  
INSERT @Text (TextValue) VALUES (@Text44)  
INSERT @Text (TextValue) VALUES (@Text45)  
INSERT @Text (TextValue) VALUES (@Text46)  
INSERT @Text (TextValue) VALUES (@Text47)  
INSERT @Text (TextValue) VALUES (@Text48)  
INSERT @Text (TextValue) VALUES (@Text49)  
INSERT @Text (TextValue) VALUES (@Text50)  
INSERT @Text (TextValue) VALUES (@Text51)  
INSERT @Text (TextValue) VALUES (@Text52)  
INSERT @Text (TextValue) VALUES (@Text53)  
INSERT @Text (TextValue) VALUES (@Text54)  
INSERT @Text (TextValue) VALUES (@Text55)  
INSERT @Text (TextValue) VALUES (@Text56)  
INSERT @Text (TextValue) VALUES (@Text57)  
INSERT @Text (TextValue) VALUES (@Text58)  
INSERT @Text (TextValue) VALUES (@Text59)  
INSERT @Text (TextValue) VALUES (@Text60)  
INSERT @Text (TextValue) VALUES (@Text61)  
INSERT @Text (TextValue) VALUES (@Text62)  
INSERT @Text (TextValue) VALUES (@Text63)  
INSERT @Text (TextValue) VALUES (@Text64)  
INSERT @Text (TextValue) VALUES (@Text65)  
INSERT @Text (TextValue) VALUES (@Text66)  
INSERT @Text (TextValue) VALUES (@Text67)  
INSERT @Text (TextValue) VALUES (@Text68)  
INSERT @Text (TextValue) VALUES (@Text69)  
INSERT @Text (TextValue) VALUES (@Text70)  
INSERT @Text (TextValue) VALUES (@Text71)  
INSERT @Text (TextValue) VALUES (@Text72)  
INSERT @Text (TextValue) VALUES (@Text73)  
INSERT @Text (TextValue) VALUES (@Text74)  
INSERT @Text (TextValue) VALUES (@Text75)  
INSERT @Text (TextValue) VALUES (@Text76)  
INSERT @Text (TextValue) VALUES (@Text77)  
INSERT @Text (TextValue) VALUES (@Text78)  
INSERT @Text (TextValue) VALUES (@Text79)  
INSERT @Text (TextValue) VALUES (@Text80)  
  
-------------------------------------------------------------------------------  
-- Get local language  
-------------------------------------------------------------------------------  
SELECT @LanguageParmId  = 8,  
 @LanguageId   = NULL  
   
SELECT @UserId = User_Id  
FROM dbo.Users  
WHERE UserName = @UserName  
  
SELECT @LanguageId = CASE WHEN isnumeric(ltrim(rtrim(Value))) = 1 THEN convert(float, ltrim(rtrim(Value)))  
    ELSE NULL  
    END  
FROM dbo.User_Parameters  
WHERE User_Id = @UserId  
 AND Parm_Id = @LanguageParmId  
  
IF @LanguageId IS NULL  
 BEGIN  
 SELECT @LanguageId = CASE WHEN isnumeric(ltrim(rtrim(Value))) = 1 THEN convert(float, ltrim(rtrim(Value)))  
     ELSE NULL  
     END  
 FROM dbo.Site_Parameters  
 WHERE Parm_Id = @LanguageParmId  
  
 IF @LanguageId IS NULL  
  BEGIN  
  SELECT @LanguageId = 0  
  END  
 END  
  
SELECT coalesce(lpt.Translated_Text, t.TextValue)  
FROM @Text t  
 LEFT JOIN dbo.Local_PG_Translations lpt ON lpt.Global_Text = t.TextValue  
      AND lpt.Language_Id = @LanguageId  
ORDER BY t.TextId ASC  
  
