import QtQuick 2.5
import QtQuick.Controls 1.4
import QtQuick.Dialogs 1.2
import QtQuick.Layouts 1.1
import Atomify 1.0

import Qt3D.Core 2.0
import Qt3D.Render 2.0
import Qt3D.Input 2.0
import Qt3D.Extras 2.0

import QtQuick.Scene3D 2.0

import SimVis 1.0
import ShaderNodes 1.0

Entity {
    id: root
    property var layer
    property bool showSurfaces: true
    property real outlineAlpha: 0.4
    property real sideAlpha: 0.2
    property vector3d origin
    property vector3d size
    property vector3d sizePlus: size.plus(Qt.vector3d(1, 1, 1))
    property var corners
    property var lights: [
        dummy
    ]

    function getScale(direction) {
        var dir = Qt.vector3d(0, 0, 0)
        dir[direction] = 1
        var added = Qt.vector3d(0.3, 0.3, 0.3)
        added[direction] = 0
        var result = sizePlus.times(dir).plus(added)
        return result
    }

    function getTranslation(direction, index) {
        var a = -0.5 + index % 2
        var b = -0.5 + Math.floor(index / 2)
        var indexVector
        switch(direction) {
        case "x":
            indexVector = Qt.vector3d(0, a, b)
            break
        case "y":
            indexVector = Qt.vector3d(b, 0, a)
            break
        case "z":
            indexVector = Qt.vector3d(a, b, 0)
            break
        }
        var scaled = sizePlus.times(indexVector)
        return scaled
    }

    function getIndexVector(direction, index) {
        var a = -0.5 + index % 2
        var b = -0.5 + Math.floor(index / 2)
        var indexVector
        switch(direction) {
        case "x":
            indexVector = Qt.vector3d(0, a, b)
            break
        case "y":
            indexVector = Qt.vector3d(b, 0, a)
            break
        case "z":
            indexVector = Qt.vector3d(a, b, 0)
            break
        }
        return indexVector
    }

    CuboidMesh {id: mesh}

    ShaderBuilderMaterial {
        id: outlineMaterial
        fragmentColor: StandardMaterial {
            color: Qt.rgba(0.6, 0.8, 1, outlineAlpha)
            lights: root.lights
        }
    }

    Entity {
        enabled: root.enabled && root.showSurfaces

        components: [
            mesh,
            layer,
            surfaceMaterial,
            //            surfaceTransform
        ]

        Timer {
            id: timer
            property real time
            property real previousTime: 0
            running: true
            repeat: true
            interval: 16
            onTriggered: {
                if(previousTime === 0) {
                    previousTime = Date.now()
                    return
                }

                time += Date.now() - previousTime
                previousTime = Date.now()
            }
        }

        Material {
            id: surfaceMaterial
            parameters: [
                Parameter { name: "origin"; value: simulator.system.origin },
                Parameter { name: "transformationMatrix"; value: simulator.system.transformationMatrix; }
            ]
            effect: Effect {
                techniques: Technique {
                    graphicsApiFilter {
                        api: GraphicsApiFilter.OpenGL
                        profile: GraphicsApiFilter.CoreProfile
                        majorVersion: 3
                        minorVersion: 3
                    }
                    filterKeys: FilterKey {
                        name: "renderingStyle"
                        value: "forward"
                    }
                    renderPasses: RenderPass {
                        id: builderRenderPass
                        shaderProgram: ShaderProgram {
                            vertexShaderCode: "
#version 330
in vec4 vertexPosition;
in vec3 vertexNormal;
uniform vec3 origin;
uniform mat4 transformationMatrix;
out vec3 normal;
out vec3 position;
uniform mat4 mvp;
uniform mat4 modelMatrix;
uniform mat4 modelView;
uniform mat3 modelNormalMatrix;
uniform mat3 modelViewNormal;
uniform vec4 meshColor;
void main()
{
    position = vertexPosition.xyz;
    position += vec3(0.5);
    mat3 m = mat3(transformationMatrix);
    m[0][0] += 1.0;
    m[1][1] += 1.0;
    m[2][2] += 1.0;
    position = m * position + origin - vec3(0.5);
    normal = modelNormalMatrix * vertexNormal;
    gl_Position = mvp * vec4(position, 1.0);
    position = (modelMatrix*vec4(position, 1.0)).xyz;
}"
                            fragmentShaderCode: fragmentShaderBuilder.finalShader
                            FragmentShaderBuilder {
                                id: fragmentShaderBuilder
                                fragmentColor: StandardMaterial {
                                    color: Qt.rgba(1, 1, 1, sideAlpha)
                                    lights: root.lights
                                }
//                                fragmentColor: StandardMaterial {
//                                    lights: root.lights
//                                    color: Add {
//                                        value1: Qt.rgba(1, 1, 1, sideAlpha)
//                                        value2: fragmentShaderBuilder.textureCoordinate
//                                    }
//                                }

//                                fragmentColor: StandardMaterial {
//                                    color: Add {
////                                        value1: Qt.rgba(1, 1, 1, sideAlpha)
//                                        value1: 0.0
//                                        value2: Multiply {
//                                            value1: CombineRgbVectorAlpha {
//                                                vector: fragmentShaderBuilder.position
//                                                alpha: 1.0
//                                            }
//                                        }
//                                    }
//                                    lights: root.lights
//                                }
                            }
                        }
                        renderStates: [
                            BlendEquationArguments {
                                sourceRgb: BlendEquationArguments.SourceAlpha
                                destinationRgb: BlendEquationArguments.OneMinusSourceAlpha
                                sourceAlpha: BlendEquationArguments.SourceAlpha
                                destinationAlpha: BlendEquationArguments.OneMinusSourceAlpha
                            },
                            BlendEquation {
                                blendFunction: BlendEquation.Add
                            }
                        ]
                    }
                }
            }
        }
    }

}
