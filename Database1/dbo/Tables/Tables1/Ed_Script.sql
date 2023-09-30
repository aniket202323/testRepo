CREATE TABLE [dbo].[Ed_Script] (
    [Ed_Script_ID] INT            IDENTITY (1, 1) NOT NULL,
    [ED_Field_Id]  INT            NULL,
    [ED_Model_Id]  INT            NULL,
    [Result_Desc]  VARCHAR (25)   NULL,
    [Script_Desc]  VARCHAR (50)   NULL,
    [TabNumber]    INT            NULL,
    [VB_Script]    VARCHAR (4000) NULL
);

