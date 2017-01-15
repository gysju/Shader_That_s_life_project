using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class PostProcessCamera : MonoBehaviour {

	public Material firstEffect;
    public Material secondeEffect;

    public bool useFirstEffect = true;

    [HeaderAttribute("effect1")]

    public float Aberation = 0.0f;
    public Vector2 AberationDir = Vector2.zero;

    [HeaderAttribute("effect2")]
    public float Speed = 0;
    public float Amplitude = 0;
    public float Frequence = 0;

    void OnRenderImage( RenderTexture source, RenderTexture destination)
	{
        if( useFirstEffect == true)
	    {
            Graphics.Blit (source, destination, firstEffect);
        }
        else
            Graphics.Blit(source, destination, secondeEffect);
    }

    void Update()
    {
        if (useFirstEffect == true)
        {
            firstEffect.SetFloat("_Aberations", Aberation);
            firstEffect.SetVector("_AberationsDir", new Vector4(AberationDir.x, AberationDir.y));
        }
        else
        {
            secondeEffect.SetFloat("_WaveSpeed", Speed);
            secondeEffect.SetFloat("_WaveAmplitude", Amplitude);
            secondeEffect.SetFloat("_WaveFrequence", Frequence);
        }
    }
}
