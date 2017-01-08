using UnityEngine;
using System.Collections;

[ExecuteInEditMode]
public class Light_Binding: MonoBehaviour 
{
    public Color tAmbiante;
	public Light tLight;

	void Start () 
    {
		tLight = transform.GetComponent<Light>();
        UpdateLight();
	}
#if UNITY_EDITOR
	void Update () 
    {
	    UpdateLight();
	}
#endif
    void UpdateLight()
    {

        Color tSunColor = tLight.color;
        float fIntensity = tLight.intensity;

        Color cPremulSunColor;
        Color modifiedAmbient;

        if(QualitySettings.activeColorSpace == ColorSpace.Linear)
        {
            cPremulSunColor = tSunColor.linear * fIntensity;
            modifiedAmbient = tAmbiante.linear;
        }
        else
        {
            cPremulSunColor = tSunColor * fIntensity;
            modifiedAmbient = tAmbiante;
        }

        Shader.SetGlobalColor("_SunColor", (tSunColor * fIntensity));
        Shader.SetGlobalVector("_SunDir", transform.forward);
        Shader.SetGlobalColor("_Ambiente", tAmbiante);
    }
}
