CREATE TABLE [erp].[erp_integration_outbound_laborVouchering_messages] (
    [id]            BIGINT             IDENTITY (1, 1) NOT NULL,
    [Event_Type]    VARCHAR (255)      NOT NULL,
    [Inserted_By]   VARCHAR (255)      NULL,
    [Inserted_Date] DATETIMEOFFSET (7) NULL,
    [Message]       NVARCHAR (MAX)     NOT NULL,
    [Message_Type]  VARCHAR (255)      NOT NULL,
    PRIMARY KEY CLUSTERED ([id] ASC)
);

