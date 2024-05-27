/*
 * Copyright (c) 2024 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#define _GL_CORE_

#include <GLES3/gl3.h>
#include <EGL/egl.h>
#include <EGL/eglext.h>
#include <native_vsync/native_vsync.h>
#include <string>

class EGLCore {
public:
    explicit EGLCore(std::string &id) : id_(id){};
    void switchAmbient();
    void switchDiffuse();
    void switchSpecular();
    void DrawSquare();
    void OnSurfaceCreated(void *window, int w, int h);
    void OnSurfaceChanged(void *window, int w, int h);
    void OnSurfaceDestroyed();

public:
    std::string id_;
    int width_;
    int height_;

private:
    void Update();
    GLuint LoadShader(GLenum type, const char *shaderSrc);
    GLuint CreateProgram(const char *vertexShader, const char *fragShader);
    GLuint CreateProgramError(const char *vertexShader, const char *fragShader);
    EGLNativeWindowType mEglWindow;
    EGLDisplay mEGLDisplay = EGL_NO_DISPLAY;
    EGLConfig mEGLConfig = nullptr;
    EGLContext mEGLContext = EGL_NO_CONTEXT;
    EGLContext mSharedEGLContext = EGL_NO_CONTEXT;
    EGLSurface mEGLSurface = nullptr;
    GLuint mProgramHandle;
    GLfloat iTime;
    GLint iTimeHandle;
    GLint positionHandle;
    OH_NativeVSync *mVsync;
};