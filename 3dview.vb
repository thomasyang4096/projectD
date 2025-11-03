Imports System.Web.Script.Serialization

Partial Class ThreeDView
    Inherits System.Web.UI.Page

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        If Not IsPostBack Then
            Dim sceneObjects As New List(Of Object)

            ' === 箭頭 ===
            For i As Integer = 1 To 3
                sceneObjects.Add(New With {
                    .type = "arrow",
                    .tooltip = $"箭頭 {i}",
                    .url = $"https://example.com/{i}",
                    .basePos = New With {.x = (i - 2) * 2, .y = 1.5, .z = 0},
                    .dir = New With {.x = Math.Cos(i), .y = 0, .z = Math.Sin(i)},
                    .phase = i
                })
            Next

            ' === 光球 ===
            For i As Integer = 1 To 3
                sceneObjects.Add(New With {
                    .type = "light",
                    .tooltip = $"光球 {i}",
                    .url = "",
                    .pos = New With {.x = (i - 2) * 2, .y = 2, .z = -3}
                })
            Next

            ' === JSON 給前端 ===
            Dim serializer As New JavaScriptSerializer()
            hfSceneData.Value = serializer.Serialize(sceneObjects)
        End If
    End Sub
End Class
