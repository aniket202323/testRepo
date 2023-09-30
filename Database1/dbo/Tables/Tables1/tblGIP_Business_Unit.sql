CREATE TABLE [dbo].[tblGIP_Business_Unit] (
    [BU_ID]              INT          IDENTITY (1, 1) NOT NULL,
    [Business_Unit_Desc] VARCHAR (50) NOT NULL,
    CONSTRAINT [PK_tblGIP_Business_Unit] PRIMARY KEY CLUSTERED ([BU_ID] ASC)
);

