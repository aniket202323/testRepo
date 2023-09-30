CREATE TABLE [dbo].[License_Mgr_Info] (
    [Database_Username] VARCHAR (200) NOT NULL,
    [License_Mgr_Node]  VARCHAR (200) NOT NULL,
    [License_Mgr_Port]  INT           NOT NULL,
    [Record_ID]         INT           NOT NULL,
    CONSTRAINT [PK_License_Mgr_Info] PRIMARY KEY CLUSTERED ([Record_ID] ASC)
);

