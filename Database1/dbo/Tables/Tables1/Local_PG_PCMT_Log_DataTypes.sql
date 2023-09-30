CREATE TABLE [dbo].[Local_PG_PCMT_Log_DataTypes] (
    [Log_id]         INT           IDENTITY (1, 1) NOT NULL,
    [Timestamp]      DATETIME      NOT NULL,
    [User_id1]       INT           NOT NULL,
    [Type]           VARCHAR (50)  NULL,
    [Data_Type_Id]   INT           NULL,
    [Data_Type_Desc] VARCHAR (255) NULL,
    [Phrase_Id]      INT           NULL,
    [Phrase_Value]   VARCHAR (255) NULL,
    [Phrase_Order]   INT           NULL
);

